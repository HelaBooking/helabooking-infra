// Global variables
def skipBuild = false
def allServices = ["user-service", "event-service", "booking-service", "ticketing-service", "notification-service", "audit-service"]
def servicesToBuild = []
def imageTag = ""
// List to store build metadata for the summary
def buildResults = []

pipeline {
    agent any

    environment {
        // Harbor ENVs
        REGISTRY_HOSTNAME = "harbor.management.ezbooking.lk"
        REGISTRY = "harbor.management.ezbooking.lk/helabooking"
        HARBOR_AUTH = credentials('harbor-credentials')
        // Git ENVs
        GIT_AUTH = credentials('git-org-credentials')
        BACKEND_REPO = "github.com/HelaBooking/helabooking-backend.git"
        // Image Building Container
        BUILDKIT_CONTAINER = "buildkit"
        AGENT_HOME = "/home/jenkins/agent"
        WORKSPACE_DIR = "${AGENT_HOME}/workspace/image-build"
    }

    stages {
        stage('Clone Backend Services Repo') {
            steps {
                ansiColor('xterm') {
                    sh """
                        echo "\033[1;34m> 📁 Preparing backend repo folder...\033[0m"
                        if [ ! -d "${WORKSPACE_DIR}" ]; then
                            mkdir -p ${WORKSPACE_DIR}
                        fi
                        cd ${WORKSPACE_DIR}

                        if [ ! -d "backend" ]; then
                            echo "\033[1;34m> ⬇️ Cloning backend repo...\033[0m"
                            git clone https://${GIT_AUTH_USR}:${GIT_AUTH_PSW}@${BACKEND_REPO} backend
                            cd backend
                        else
                            echo "\033[1;34m> 🔄 Backend folder exists → pulling latest...\033[0m"
                            cd backend
                            git reset --hard
                            git fetch --all
                        fi

                        git checkout ${BRANCH_NAME}
                        git pull origin ${BRANCH_NAME}
                    """
                }
            }
        }

        stage('Preparing Build') {
            steps {
                script {
                    sh "cd ${WORKSPACE_DIR}/backend && git fetch --prune"

                    // Detect changed files
                    def changes = sh(
                        script: "cd ${WORKSPACE_DIR}/backend && git diff --name-only HEAD~1 HEAD",
                        returnStdout: true
                    ).trim().split("\n")

                    echo "Changed files: ${changes}"

                    // Reset globals
                    servicesToBuild = []
                    skipBuild = false
                    imageTag = ""
                    buildResults = []

                    def commonChanged = changes.any { it.startsWith("common/") }
                    def rootPomChanged = changes.contains("pom.xml")

                    if (commonChanged || rootPomChanged) {
                        servicesToBuild = allServices
                    } else {
                        servicesToBuild = allServices.findAll { svc ->
                            changes.any { it.startsWith("${svc}/") }
                        }
                    }

                    if (servicesToBuild.isEmpty()) {
                        echo "\033[1;33mNo service changes → skipping build\033[0m"
                        skipBuild = true
                    } else {
                        echo "\033[1;32mServices to build → ${servicesToBuild}\033[0m"
                    }

                    // Tag based on branch
                    def shortCommit = sh(
                        script: "cd ${WORKSPACE_DIR}/backend && git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    switch(env.BRANCH_NAME) {
                        case "dev":  imageTag = "dev-${shortCommit}"; break
                        case "qa":   imageTag = "qa-${shortCommit}"; break
                        case "stag": imageTag = "stag-${shortCommit}"; break
                        case "main": imageTag = "prod-${shortCommit}"; break
                    }
                }
            }
        }

        stage('Build & Push Images') {
            when { expression { return !skipBuild } }
            steps {
                ansiColor('xterm') {
                    script {
                        withCredentials([
                            usernamePassword(
                                credentialsId: 'harbor-credentials',
                                usernameVariable: 'HARBOR_USER',
                                passwordVariable: 'HARBOR_PASS'
                            )
                        ]) {
                            // 1. Write Auth
                            sh """
                                if [ ! -d "${AGENT_HOME}/.docker" ]; then
                                    echo "> 🗝 Writing Docker auth config..."
                                    mkdir -p ${AGENT_HOME}/.docker
                                    echo '{"auths":{"${REGISTRY}":{"username":"${HARBOR_USER}","password":"${HARBOR_PASS}"}}}' > ${AGENT_HOME}/.docker/config.json
                                fi
                            """
                            
                            // 2. Iterate and Build
                            servicesToBuild.each { svc ->
                                def startTime = System.currentTimeMillis()
                                
                                // Visual Separator for Logs
                                printHeader(svc, imageTag)

                                container("${BUILDKIT_CONTAINER}") {
                                    withEnv(["DOCKER_CONFIG=${AGENT_HOME}/.docker"]) {
                                        // Build and capture metadata using 'metadata-file'
                                        sh """
                                            buildctl build \
                                                --frontend=dockerfile.v0 \
                                                --local context=${WORKSPACE_DIR}/backend \
                                                --local dockerfile=${WORKSPACE_DIR}/backend/${svc} \
                                                --output type=image,registry.insecure=true,name=${REGISTRY}/${svc}:${imageTag},push=true \
                                                --import-cache type=registry,ref=${REGISTRY}/${svc}:cache \
                                                --export-cache type=registry,ref=${REGISTRY}/${svc}:cache,mode=max \
                                                --metadata-file ${AGENT_HOME}/metadata-${svc}.json
                                        """
                                    }
                                }
                                
                                // Calculate duration
                                def duration = (System.currentTimeMillis() - startTime) / 1000
                                
                                // Read image size (approximation via buildctl doesn't give easy size, 
                                // so we will log the digest and success)
                                def metadata = readJSON file: "${AGENT_HOME}/metadata-${svc}.json"
                                def digest = metadata['containerimage.digest']
                                
                                // Store result
                                buildResults.add([
                                    service: svc,
                                    tag: imageTag,
                                    duration: "${duration}s",
                                    digest: digest
                                ])

                                echo "\033[1;32m> ✅ Successfully pushed ${svc}:${imageTag}\033[0m"
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                if (!skipBuild && !buildResults.isEmpty()) {
                    printSummary(buildResults, REGISTRY)
                }
            }
        }
    }
}

// --- Helper Functions ---

def printHeader(serviceName, tag) {
    echo """
\033[1;36m================================================================================
  🔨 BUILDING SERVICE: ${serviceName}
  🏷️  TAG: ${tag}
================================================================================\033[0m
"""
}

def printSummary(results, registryUrl) {
    def summary = """
\033[1;35m
================================================================================
                        🚀 BUILD & PUSH SUMMARY
================================================================================
\033[0m"""
    
    summary += String.format("| %-20s | %-15s | %-10s | %-20s |\n", "Service", "Tag", "Duration", "Status")
    summary += "|----------------------|-----------------|------------|----------------------|\n"

    results.each { res ->
        summary += String.format("| %-20s | %-15s | %-10s | \033[1;32m%-20s\033[0m |\n", res.service, res.tag, res.duration, "PUSHED")
    }
    
    summary += "================================================================================"
    
    echo summary
}