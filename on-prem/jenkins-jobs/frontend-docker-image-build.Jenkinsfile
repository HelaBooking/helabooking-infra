// Global variables
def skipBuild = false
// Define the name of the frontend app (used for image naming)
def appName = "frontend" 
def servicesToBuild = []
def imageTag = ""
def buildResults = []

// --- TRIGGER CONFIGURATION ---
def targetRepo = "helabooking-frontend"                 // GitHub Repo Name
def allowedBranchesTriggers = ["dev", "qa"]             // Branches allowed to trigger

// Apply Trigger ONLY if the current branch is in the allowed list
if (allowedBranchesTriggers.contains(env.BRANCH_NAME)) {
    properties([
        pipelineTriggers([
            [$class: 'GenericTrigger',
            genericVariables: [
                [key: 'REPO_NAME', value: '$.repository.name'],
                [key: 'REF', value: '$.ref']
            ],
            token: 'frontend-trigger',
            printContributedVariables: true,
            printPostContent: false,
            
            // Trigger if Repo Name matches AND Branch matches this pipeline's branch
            regexpFilterText: '$REPO_NAME $REF',
            regexpFilterExpression: "^${targetRepo} refs/heads/${env.BRANCH_NAME}\$" 
            ]
        ])
    ])
}

pipeline {
    agent any

    environment {
        // Harbor ENVs
        REGISTRY_HOSTNAME = "harbor.management.ezbooking.lk"
        REGISTRY = "harbor.management.ezbooking.lk/helabooking"
        HARBOR_AUTH = credentials('harbor-credentials')
        
        // Git ENVs
        GIT_AUTH = credentials('git-org-credentials')
        // Update this URL to your actual Frontend Repo
        FRONTEND_REPO = "github.com/HelaBooking/helabooking-frontend.git" 
        
        BUILDKIT_CONTAINER = "buildkit"
        
        // Paths
        AGENT_HOME = "/home/jenkins/agent"
        WORKSPACE_DIR = "${AGENT_HOME}/workspace/frontend-image-build"
    }

    stages {
        stage('Clone Frontend Repo') {
            steps {
                ansiColor('xterm') {
                    sh """
                        echo "\033[1;34m> 📁 Preparing frontend repo folder...\033[0m"
                        if [ ! -d "${WORKSPACE_DIR}" ]; then
                            mkdir -p ${WORKSPACE_DIR}
                        fi
                        cd ${WORKSPACE_DIR}

                        if [ ! -d "frontend" ]; then
                            echo "\033[1;34m> ⬇️ Cloning frontend repo...\033[0m"
                            git clone https://${GIT_AUTH_USR}:${GIT_AUTH_PSW}@${FRONTEND_REPO} frontend
                            cd frontend
                        else
                            echo "\033[1;34m> 🔄 Frontend folder exists → pulling latest...\033[0m"
                            cd frontend
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
                    sh "cd ${WORKSPACE_DIR}/frontend && git fetch --prune"

                    // Detect changed files
                    def changes = sh(
                        script: "cd ${WORKSPACE_DIR}/frontend && git diff --name-only HEAD~1 HEAD",
                        returnStdout: true
                    ).trim().split("\n")

                    echo "Changed files: ${changes}"

                    // Reset globals
                    servicesToBuild = []
                    skipBuild = false
                    imageTag = ""
                    buildResults = []

                    // Logic: If ANY file changed in the frontend repo, rebuild the app.
                    // You can add exclusions here (e.g. if only README.md changed)
                    if (changes.length > 0) {
                        servicesToBuild.add(appName)
                    }

                    if (servicesToBuild.isEmpty()) {
                        echo "\033[1;33mNo changes detected → skipping build\033[0m"
                        skipBuild = true
                    } else {
                        echo "\033[1;32mBuilding Frontend → ${servicesToBuild}\033[0m"
                    }

                    // Tag based on branch
                    def shortCommit = sh(
                        script: "cd ${WORKSPACE_DIR}/frontend && git rev-parse --short HEAD",
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

        stage('Build & Push Image') {
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
                            
                            // 2. Build
                            servicesToBuild.each { svc ->
                                def startTime = System.currentTimeMillis()
                                def metadataFileName = "metadata-${svc}.json"
                                
                                printHeader(svc, imageTag)

                                container("${BUILDKIT_CONTAINER}") {
                                    withEnv(["DOCKER_CONFIG=${AGENT_HOME}/.docker"]) {
                                        // Note: Context is now the ROOT of the frontend folder
                                        sh """
                                            buildctl build \
                                                --frontend=dockerfile.v0 \
                                                --local context=${WORKSPACE_DIR}/frontend \
                                                --local dockerfile=${WORKSPACE_DIR}/frontend \
                                                --output type=image,registry.insecure=true,name=${REGISTRY}/${svc}:${imageTag},push=true \
                                                --import-cache type=registry,ref=${REGISTRY}/${svc}:cache \
                                                --export-cache type=registry,ref=${REGISTRY}/${svc}:cache,mode=max \
                                                --metadata-file ${metadataFileName}
                                        """
                                    }
                                }
                                
                                def duration = (System.currentTimeMillis() - startTime) / 1000
                                
                                // Manual JSON Parsing (Digest extraction)
                                def digest = "unknown"
                                if (fileExists(metadataFileName)) {
                                    def fileContent = readFile(file: metadataFileName)
                                    def matcher = (fileContent =~ /"containerimage.digest":\s*"([^"]+)"/)
                                    if (matcher.find()) {
                                        digest = matcher[0][1].replace("sha256:", "").take(7)
                                    }
                                }
                                
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
  🔨 BUILDING APP: ${serviceName}
  🏷️  TAG: ${tag}
================================================================================\033[0m
"""
}

def printSummary(results) {
    def summary = "\n\033[1;35m================================================================================\n"
    summary += "                        🚀 BUILD & PUSH SUMMARY\n"
    summary += "================================================================================\033[0m\n"
    
    summary += String.format("| %-20s | %-15s | %-10s | %-10s |\n", "App", "Tag", "Time", "Digest")
    summary += "|----------------------|-----------------|------------|------------|\n"

    results.each { res ->
        summary += String.format("| %-20s | %-15s | %-10s | %-10s |\n", res.service, res.tag, res.duration, res.digest)
    }
    
    summary += "================================================================================"
    echo summary
}