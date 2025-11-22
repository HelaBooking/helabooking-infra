// Global variables
def skipBuild = false
def allServices = ["user-service", "event-service", "booking-service", "ticketing-service", "notification-service", "audit-service"]
def servicesToBuild = []
def imageTag = ""


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
        // SERVICES = Refer Line 59
        // Image Building Container
        BUILDKIT_CONTAINER = "buildkit"
        // The Jenkins Plugin forces the mount at /home/jenkins/agent
        AGENT_HOME = "/home/jenkins/agent"
        WORKSPACE_DIR = "${AGENT_HOME}/workspace/image-build"
    }

    stages {
        stage('Clone Backend Services Repo') {
            steps {
                ansiColor('xterm') {
                    sh """
                        echo "> 📁 Preparing backend repo folder..."
                        if [ ! -d "${WORKSPACE_DIR}" ]; then
                            mkdir -p ${WORKSPACE_DIR}
                        fi
                        cd ${WORKSPACE_DIR}

                        if [ ! -d "backend" ]; then
                            echo "> ⬇️ Cloning backend repo..."
                            git clone https://${GIT_AUTH_USR}:${GIT_AUTH_PSW}@${BACKEND_REPO} backend
                            cd backend
                        else
                            echo "> 🔄 Backend folder exists → pulling latest..."
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
                        echo "No service changes → skipping build"
                        skipBuild = true
                    } else {
                        echo "Services to build → ${servicesToBuild}"
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

        stage('Build & Push Images to Harbor') {
            when { expression { return !skipBuild } }
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'harbor-credentials',
                            usernameVariable: 'HARBOR_USER',
                            passwordVariable: 'HARBOR_PASS'
                        )
                    ]) {
                        // 1. Write Auth to the SHARED HOME directory
                        sh """
                            if [ ! -d "${AGENT_HOME}/.docker" ]; then
                                echo "> 🗝 Writing Docker auth config for BuildKit..."
                                mkdir -p ${AGENT_HOME}/.docker
                                echo '{"auths":{"${REGISTRY}":{"username":"${HARBOR_USER}","password":"${HARBOR_PASS}"}}}' > ${AGENT_HOME}/.docker/config.json
                            fi
                        """
                        // Build and push images
                        servicesToBuild.each { svc ->
                            echo "> 🔨 Building image for ${svc}..."

                            container("${BUILDKIT_CONTAINER}") {
                                // Explicitly set DOCKER_CONFIG so BuildKit finds the file
                                withEnv(["DOCKER_CONFIG=${AGENT_HOME}/.docker"]) {
                                    sh """
                                        buildctl build \
                                            --frontend=dockerfile.v0 \
                                            --local context=${WORKSPACE_DIR}/backend \
                                            --local dockerfile=${WORKSPACE_DIR}/backend/${svc} \
                                            --output type=image,registry.insecure=true,name=${REGISTRY}/${svc}:${imageTag},push=true \
                                            --import-cache type=registry,ref=${REGISTRY}/${svc}:cache \
                                            --export-cache type=registry,ref=${REGISTRY}/${svc}:cache,mode=max
                                    """
                                }
                            }
                            echo "> 📤 Pushed ${svc}:${imageTag} to ${REGISTRY}"
                        }
                    }
                }
            }
        }
    }
}