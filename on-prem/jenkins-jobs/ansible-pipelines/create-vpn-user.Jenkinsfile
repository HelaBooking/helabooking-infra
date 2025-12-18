pipeline {
    agent any

    parameters {
        gitParameter(
            name: 'BRANCH_NAME', 
            type: 'PT_BRANCH', 
            defaultValue: 'origin/aws-main', 
            selectedValue: 'TOP', 
            sortMode: 'ASCENDING_SMART', 
            branchFilter: 'origin/(aws-.*)', 
            tagFilter: '*', 
            description: 'Select the Source Branch (e.g., aws-main). The job will manage VPN users in <branch>-infra.'
        )

        string(
            name: 'VPN_USERNAME',
            defaultValue: '',
            description: 'WireGuard VPN username (required)'
        )
    }

    environment {
        // --- CONFIGURATION ---
        SECRETS_BUCKET = 'group9-secrets-bucket'

        // AWS Credentials
        AWS_REGION = 'ap-southeast-1'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')

        // Ansible Config
        ANSIBLE_CONFIG = "${WORKSPACE}/ansible/ansible.cfg"
        ANSIBLE_FORCE_COLOR = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        PYTHONUNBUFFERED = '1'
    }

    stages {

        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.VPN_USERNAME?.trim()) {
                        error "❌ VPN_USERNAME is required."
                    }
                }
            }
        }

        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: "${params.BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        credentialsId: 'git-org-credentials',
                        url: 'https://github.com/HelaBooking/helabooking-infra.git'
                    ]]
                ])
            }
        }

        stage('Fetch Configuration') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [1/4] Determining Environment Configuration..."
                        def cleanBranch = params.BRANCH_NAME.replace('origin/', '')
                        env.ENV_NAME = "${cleanBranch}-infra"
                        env.S3_METADATA_PATH = "cloud/${env.ENV_NAME}/metadata.json"

                        sh "aws s3 cp s3://${SECRETS_BUCKET}/${env.S3_METADATA_PATH} metadata.json"

                        env.SSH_SECRET_ID = sh(script: "jq -r '.ssh_secret_id' metadata.json", returnStdout: true).trim()
                        env.SSH_KEY_NAME = "${sh(script: "jq -r '.ssh_key_name' metadata.json", returnStdout: true).trim()}.pem"

                        if (!env.SSH_SECRET_ID || env.SSH_SECRET_ID == "null") {
                            error "❌ Invalid metadata.json (missing ssh_secret_id)"
                        }

                        echo "> 🟢 [1/4] Configuration Retrieved!"
                    }
                }
            }
        }

        stage('Retrieve SSH Key') {
            steps {
                ansiColor('xterm') {
                    dir("cloud/${env.ENV_NAME}") {
                        sh '''
                            echo "> 🔃 [2/4] Fetching SSH Key..."
                            mkdir -p keys
                            aws secretsmanager get-secret-value \
                                --secret-id ${SSH_SECRET_ID} \
                                --region ${AWS_REGION} \
                                --query SecretString \
                                --output text > keys/${SSH_KEY_NAME}
                            chmod 600 keys/${SSH_KEY_NAME}
                            echo "> 🟢 [2/4] SSH Key fetched!"
                        '''
                    }
                }
            }
        }

        stage('Create / Fetch VPN User') {
            steps {
                ansiColor('xterm') {
                    sh "cp metadata.json cloud/${env.ENV_NAME}/metadata.json"

                    dir("cloud/${env.ENV_NAME}/ansible") {
                        script {
                            echo "> 🔃 [3/4] Managing VPN user: ${params.VPN_USERNAME}"
                            sh '''
                            mkdir -p tmp/vpn-users
                            '''
                            def status = sh(script: """
                                chmod +x inventory/dynamic_inventory.py
                                ansible-playbook setup_vpn_user.yml \
                                    -e vpn_username=${params.VPN_USERNAME}
                            """, returnStatus: true)

                            if (status != 0) {
                                error "❌ VPN user creation failed."
                            } else {
                                echo "> 🟢 [3/4] VPN user ${params.VPN_USERNAME} managed successfully!"
                            }
                        }
                    }
                }
            }
        }

        stage('Collect & Archive User Config') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [4/4] Collecting VPN config..."
                        def userConfPath = "cloud/${env.ENV_NAME}/ansible/tmp/vpn-users/${params.VPN_USERNAME}.conf"
                        if (!fileExists(userConfPath)) {
                            error "❌ VPN config file not saved to ${userConfPath}"
                        }   
                        archiveArtifacts artifacts: userConfPath, allowEmptyArchive: false
                        echo "> 🟢 [4/4] VPN config archived for ${params.VPN_USERNAME}!"
                    }
                }
            }
        }

    }

    post {
        success {
            echo "✅ VPN User '${params.VPN_USERNAME}' processed successfully for ${env.ENV_NAME}"
        }
        failure {
            echo "❌ VPN User pipeline failed for ${env.ENV_NAME}"
        }
    }
}
