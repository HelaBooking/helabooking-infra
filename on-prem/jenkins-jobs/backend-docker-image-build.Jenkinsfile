// Global variables
def skipBuild = false
def allServices = ["user-service", "event-service", "booking-service", "ticketing-service", "notification-service", "audit-service"]
def servicesToBuild = []
def imageTag = ""
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
        // BuildKit Container Name
        BUILDKIT_CONTAINER = "buildkit"
        // Paths
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
                                def metadataFileName = "metadata-${svc}.json"
                                
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
                                                --metadata-file ${metadataFileName}
                                        """
                                    }
                                }
                                
                                // Calculate duration
                                def duration = (System.currentTimeMillis() - startTime) / 1000
                                
                                // Read image size
                                def digest = "unknown"
                                if (fileExists(metadataFileName)) {
                                    def fileContent = readFile(file: metadataFileName)
                                    // Regex to look for "containerimage.digest": "sha256:..."
                                    def matcher = (fileContent =~ /"containerimage.digest":\s*"([^"]+)"/)
                                    if (matcher.find()) {
                                        digest = matcher[0][1] // Get the capture group
                                        // Shorten digest for display (sha256:12345... -> 1234567)
                                        digest = digest.replace("sha256:", "").take(7)
                                    }
                                }
                                
                                buildResults.add([
                                    service: svc,
                                    tag: imageTag,
                                    duration: "${duration}s",
                                    digest: digest
                                ])

                                echo "\033[1;32m> ✅ Successfully pushed ${svc}:${imageTag} (Digest: ${digest})\033[0m"
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
                    printSummary(buildResults)
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

def printSummary(results) {
    // Header
    def summary = "\n\033[1;35m================================================================================\n"
    summary += "                        🚀 BUILD & PUSH SUMMARY\n"
    summary += "================================================================================\033[0m\n"
    
    // Table Header
    // Note: Jenkins console isn't monospaced perfectly, but we try our best
    summary += String.format("| %-20s | %-15s | %-10s | %-10s |\n", "Service", "Tag", "Time", "Digest")
    summary += "|----------------------|-----------------|------------|------------|\n"

    // Rows
    results.each { res ->
        summary += String.format("| %-20s | %-15s | %-10s | %-10s |\n", res.service, res.tag, res.duration, res.digest)
    }
    
    summary += "================================================================================"
    
    echo summary
}