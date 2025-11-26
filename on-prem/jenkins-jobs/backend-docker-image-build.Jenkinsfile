// Global variables
def skipBuild = false
def allServices = ["user-service", "event-service", "booking-service", "ticketing-service", "notification-service", "audit-service"]
def servicesToBuild = []
def imageTag = ""
def buildResults = []

// --- TRIGGER CONFIGURATION ---
def targetRepo = "helabooking-backend"                  // trigger repo name
def allowedBranchesTriggers = ["dev", "qa"]             // branches allowed to trigger this pipeline

// Apply Trigger ONLY if the current branch is in the allowed list
if (allowedBranchesTriggers.contains(env.BRANCH_NAME)) {
    properties([
        pipelineTriggers([
            [$class: 'GenericTrigger',
            // Extract variables from the GitHub JSON Payload
            genericVariables: [
                [key: 'REPO_NAME', value: '$.repository.name'],
                [key: 'REF', value: '$.ref']
            ],
            token: 'backend-trigger',
            printContributedVariables: true,
            printPostContent: false,
            
            // The Filter:
            // This constructs a string like "helabooking-backend refs/heads/dev" and checks if it matches the Regex.
            // It ensures this pipeline ONLY runs if the webhook comes from the backend repo and the branch matches the current pipeline branch.
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

        stage('Preparing & Checking Registry') {
            steps {
                script {
                    ansiColor('xterm') {
                        sh "cd ${WORKSPACE_DIR}/backend && git fetch --prune"

                        // 1. Identify Changed Services via Git
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
                        def initialList = []

                        if (commonChanged || rootPomChanged) {
                            initialList = allServices
                        } else {
                            initialList = allServices.findAll { svc ->
                                changes.any { it.startsWith("${svc}/") }
                            }
                        }

                        // 2. Calculate Tag
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

                        if (initialList.isEmpty()) {
                            echo "\033[1;33mNo service changes detected.\033[0m"
                            skipBuild = true
                        } else {
                            echo "\033[1;34m> 🔍 Checking Registry for existing images for tag: ${imageTag}...\033[0m"
                            
                            // Check Registry for Existing Images
                            withCredentials([
                                usernamePassword(
                                    credentialsId: 'harbor-credentials',
                                    usernameVariable: 'HARBOR_USER',
                                    passwordVariable: 'HARBOR_PASS'
                                )
                            ]) {
                                // Generate BuildKit Config (needed for build stage)
                                sh '''
                                    mkdir -p $AGENT_HOME/.docker
                                    echo "{\\"auths\\":{\\"$REGISTRY\\":{\\"username\\":\\"$HARBOR_USER\\",\\"password\\":\\"$HARBOR_PASS\\"}}}" > $AGENT_HOME/.docker/config.json
                                '''
                                // Check each service image via Harbor V2 API
                                initialList.each { svc ->
                                    // Harbor V2 API URL: https://<host>/v2/<project>/<repo>/manifests/<tag>
                                    def apiUrl = "https://${REGISTRY_HOSTNAME}/v2/helabooking/${svc}/manifests/${imageTag}"
                                    withEnv(["CHECK_URL=${apiUrl}"]) {
                                        def exists = sh(
                                            script: 'curl -k -I -f -u "$HARBOR_USER:$HARBOR_PASS" "$CHECK_URL" > /dev/null 2>&1',
                                            returnStatus: true
                                        ) == 0

                                        if (exists) {
                                            echo "\033[1;33m> ⏭️  Skipping ${svc} (Image ${imageTag} found in registry via API)\033[0m"
                                    // Add to results as "SKIPPED" for the final report
                                            buildResults.add([
                                                service: svc,
                                                tag: imageTag,
                                                duration: "0s",
                                                digest: "SKIPPED (Exists)"
                                            ])
                                        } else {
                                            echo "\033[1;32m> ➕ Adding ${svc} to build list (Not found in registry)\033[0m"
                                            servicesToBuild.add(svc)
                                        }
                                    }
                                }
                            }
                        }

                        // 4. Final Decision
                        if (servicesToBuild.isEmpty()) {
                            echo "\033[1;33mAll changed services already exist in registry. Nothing to build.\033[0m"
                            skipBuild = true
                        } else {
                            echo "\033[1;36mFinal list to build: ${servicesToBuild}\033[0m"
                            skipBuild = false 
                        }
                    }
                }
            }
        }

        stage('Build & Push Images') {
            when { expression { return !skipBuild } }
            steps {
                ansiColor('xterm') {
                    script {
                        // Auth file is already created in the previous stage, 
                        // but we ensure the env is passed.
                        // Iterate and Build
                        servicesToBuild.each { svc ->
                            def startTime = System.currentTimeMillis()
                            def metadataFileName = "metadata-${svc}.json"
                            
                            printHeader(svc, imageTag)

                            container("${BUILDKIT_CONTAINER}") {
                                withEnv(["DOCKER_CONFIG=${AGENT_HOME}/.docker"]) {
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
                            
                            def duration = (System.currentTimeMillis() - startTime) / 1000
                            
                            // Manual JSON Parsing for summary
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

                            echo "\033[1;32m> ✅ Successfully pushed ${svc}:${imageTag} (Digest: ${digest})\033[0m"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Always print summary if we have results (even if some were skipped)
                if (!buildResults.isEmpty()) {
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
    def summary = "\n\033[1;35m================================================================================\n"
    summary += "                        🚀 BUILD & PUSH SUMMARY\n"
    summary += "================================================================================\033[0m\n"
    
    summary += String.format("| %-20s | %-15s | %-10s | %-20s |\n", "Service", "Tag", "Time", "Digest/Status")
    summary += "|----------------------|-----------------|------------|----------------------|\n"

    results.each { res ->
        def statusColor = res.digest.contains("SKIPPED") ? "\033[1;33m" : "\033[1;32m" // Yellow for skip, Green for success
        summary += String.format("| %-20s | %-15s | %-10s | ${statusColor}%-20s\033[0m |\n", res.service, res.tag, res.duration, res.digest)
    }
    
    summary += "================================================================================"
    echo summary
}