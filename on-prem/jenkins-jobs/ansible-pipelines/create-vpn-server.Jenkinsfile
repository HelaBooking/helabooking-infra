pipeline {
    agent any

    parameters {
        // Git Parameter: Lists branches starting with 'aws-'
        gitParameter(
            name: 'BRANCH_NAME', 
            type: 'PT_BRANCH', 
            defaultValue: 'origin/aws-main', 
            selectedValue: 'TOP', 
            sortMode: 'ASCENDING_SMART', 
            branchFilter: 'origin/(aws-.*)', 
            tagFilter: '*', 
            description: 'Select the Source Branch (e.g., aws-main). The job will deploy VPN to <branch>-infra environment.'
        )
    }

    environment {
        // --- CONFIGURATION ---
        SECRETS_BUCKET = 'group9-secrets-bucket'
        
        // AWS Credentials
        AWS_REGION = 'ap-southeast-1' // Default
        AWS_REGION_S3 = 'ap-southeast-1'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')

        // Ansible Config
        ANSIBLE_CONFIG = "${WORKSPACE}/ansible/ansible.cfg"
        ANSIBLE_FORCE_COLOR = 'true'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        PYTHONUNBUFFERED = '1'
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM', 
                    branches: [[name: "${params.BRANCH_NAME}"]], 
                    userRemoteConfigs: [[credentialsId: 'git-org-credentials', url: 'https://github.com/HelaBooking/helabooking-infra.git']]
                ])
            }
        }

        stage('Install Tools') {
            steps {
                ansiColor('xterm') {
                    sh '''
                        echo "> 🔃 [1/5] Installing Dependencies..."
                        apt-get update && apt-get install -y python3-pip python3-venv sshpass jq awscli
                        pip3 install ansible boto3 --break-system-packages

                        # Setup AWS CLI:
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        echo "> 🟢 [1/5] Tools Ready"
                    '''
                }
            }
        }

        stage('Fetch Configuration') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [1/5] Determining Environment Configuration..."
                        def cleanBranch = params.BRANCH_NAME.replace('origin/', '')
                        env.ENV_NAME = "${cleanBranch}-infra"
                        env.S3_METADATA_PATH = "cloud/${env.ENV_NAME}/metadata.json"

                        echo "============================================="
                        echo "   Selected Branch: ${cleanBranch}"
                        echo "   Target Env     : ${env.ENV_NAME}"
                        echo "   S3 Metadata    : ${env.S3_METADATA_PATH}"
                        echo "============================================="

                        sh "aws s3 --region ${AWS_REGION_S3} cp s3://${SECRETS_BUCKET}/${env.S3_METADATA_PATH} metadata.json"
                        env.SSH_SECRET_ID = sh(script: "jq -r '.ssh_secret_id' metadata.json", returnStdout: true).trim()
                        env.SSH_KEY_NAME = "${sh(script: "jq -r '.ssh_key_name' metadata.json", returnStdout: true).trim()}.pem"
                        env.PROJECT_NAME = sh(script: "jq -r '.project_name' metadata.json", returnStdout: true).trim()
                        env.AWS_REGION = sh(script: "jq -r '.region' metadata.json", returnStdout: true).trim()

                        if (!env.SSH_SECRET_ID || env.SSH_SECRET_ID == "null") {
                            error "❌ [1/5] Metadata invalid: 'ssh_secret_id' missing."
                        } else {
                            echo "> 🔑 SSH Secret ID: ${env.SSH_SECRET_ID}"
                            echo "> 🗝️ SSH Key Name  : ${env.SSH_KEY_NAME}"
                            echo "> 📁 Project Name : ${env.PROJECT_NAME}"
                            echo "> 🟢 [1/5] Configuration Retrieved!"
                        }
                    }
                }
            }
        }

        stage('Retrieve SSH Key') {
            steps {
                ansiColor('xterm') {
                    dir("cloud/${env.ENV_NAME}") {
                        sh '''
                            echo "> 🔃 [2/5] Fetching SSH Key from Secrets Manager..."
                            mkdir -p keys
                            aws secretsmanager get-secret-value \
                                --secret-id ${SSH_SECRET_ID} \
                                --region ${AWS_REGION} \
                                --query SecretString \
                                --output text > keys/${SSH_KEY_NAME}
                            chmod 600 keys/${SSH_KEY_NAME}

                            if [ ! -s "keys/${SSH_KEY_NAME}" ]; then
                                echo "❌ [2/5] Error: Retrieved SSH key is empty."
                                exit 1
                            fi
                            echo "> 🟢 [2/5] SSH Key Retrieved into ${PWD}/keys!"
                        '''
                    }
                }
            }
        }

        stage('Setup WireGuard VPN') {
            steps {
                ansiColor('xterm') {
                    // Copy metadata.json to where dynamic_inventory.py expects it
                    sh "cp metadata.json cloud/${env.ENV_NAME}/metadata.json"
                    dir("cloud/${env.ENV_NAME}/ansible") {
                        script {
                            echo "> 🔃 [3/5] Running Ansible to setup WireGuard VPN..."
                            
                            def status = sh(script: '''
                                chmod +x inventory/dynamic_inventory.py
                                ansible-playbook setup_vpn.yml
                            ''', returnStatus: true)
                            
                            if (status != 0) {
                                error "❌ [3/5] WireGuard VPN setup failed. Check Ansible logs."
                            } else {
                                echo "> 🟢 WireGuard VPN setup completed successfully."
                            }
                        }
                    }
                }
            }
        }

        stage('Post-Setup Validation') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [4/5] Validating VPN setup..."
                        // Optional: run a lightweight test to verify VPN node is reachable
                        sh '''
                            echo "VPN nodes should now be reachable. Manual check recommended."
                        '''
                        echo "> 🟢 [4/5] VPN pipeline finished."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ WireGuard VPN Setup Complete for ${env.ENV_NAME}"
        }
        failure {
            echo "❌ WireGuard VPN Setup Failed for ${env.ENV_NAME}"
        }
    }
}
