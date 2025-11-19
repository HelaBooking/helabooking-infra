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
    }

    stages {

        stage('Clone Backend Services Repo') {
            steps {
                ansiColor('xterm') {
                    sh '''
                        echo "> 📁 Preparing backend repo folder..."

                        if [ ! -d "/home/jenkins/agent/workspace/image-build" ]; then
                            mkdir -p /home/jenkins/agent/workspace/image-build
                        fi
                        cd /home/jenkins/agent/workspace/image-build

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
                    '''
                }
            }
        }

        stage('Preparing Build') {
            steps {
                script {
                    sh "cd /home/jenkins/agent/workspace/image-build/backend && git fetch --prune"

                    // Detect changed files
                    def changes = sh(
                        script: "cd /home/jenkins/agent/workspace/image-build/backend && git diff --name-only HEAD~1 HEAD",
                        returnStdout: true
                    ).trim().split("\n")

                    echo "Changed files: ${changes}"

                    def ALL_SERVICES = ["user-service", "event-service", "booking-service", "ticketing-service", "notification-service", "audit-service"]
                    def SERVICES_TO_BUILD = []
                    def skipBuild = false
                    def IMAGE_TAG = ""

                    def commonChanged = changes.any { it.startsWith("common/") }
                    def rootPomChanged = changes.contains("pom.xml")

                    if (commonChanged || rootPomChanged) {
                        SERVICES_TO_BUILD = ALL_SERVICES
                    } else {
                        SERVICES_TO_BUILD = ALL_SERVICES.findAll { svc ->
                            changes.any { it.startsWith("${svc}/") }
                        }
                    }

                    if (SERVICES_TO_BUILD.isEmpty()) {
                        echo "No service changes → skipping build"
                        skipBuild = true
                    } else {
                        echo "Services to build → ${SERVICES_TO_BUILD}"
                    }

                    // Tag based on branch
                    def shortCommit = sh(
                        script: "cd /home/jenkins/agent/workspace/image-build/backend && git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    switch(env.BRANCH_NAME) {
                        case "dev":  IMAGE_TAG = "dev-${shortCommit}"; break
                        case "qa":   IMAGE_TAG = "qa-${shortCommit}"; break
                        case "stag": IMAGE_TAG = "stag-${shortCommit}"; break
                        case "main": IMAGE_TAG = "prod-${shortCommit}"; break
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
                        // Create auth file for buildkit push
                        sh '''
                            if [ ! -d "/workspace/.docker" ]; then
                                echo "> 🗝 Writing Docker auth config for BuildKit..."
                                mkdir -p /workspace/.docker
                                echo '{"auths":{"${REGISTRY}":{"username":"${HARBOR_USER}","password":"${HARBOR_PASS}"}}}' > /workspace/.docker/config.json
                            fi
                        '''
                        // Build and push images
                        SERVICES_TO_BUILD.each { svc ->

                            echo "> 🔨 Building image for ${svc}..."

                            container("${BUILDKIT_CONTAINER}") {
                                sh """
                                    buildctl build \
                                        --frontend=dockerfile.v0 \
                                        --local context=/workspace/image-build/backend/${svc} \
                                        --local dockerfile=/workspace/image-build/backend/${svc} \
                                        --output type=registry,registry.insecure=true,tlsservername=${REGISTRY_HOSTNAME},name=${REGISTRY}/${svc}:${IMAGE_TAG},push=true

                                        --import-cache type=registry,ref=${REGISTRY}/${svc}:cache \
                                        --export-cache type=registry,ref=${REGISTRY}/${svc}:cache,mode=max
                                """
                            }

                            echo "> 📤 Pushed ${svc}:${IMAGE_TAG} to ${REGISTRY}"
                        }
                    }
                }
            }
        }
    }
}
