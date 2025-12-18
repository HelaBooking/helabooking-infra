pipeline {
    agent any

    parameters {
        // Git Parameter: Lists branches from the Repo
        gitParameter(name: 'BRANCH_NAME', 
                    type: 'PT_BRANCH', 
                    defaultValue: 'origin/aws-main', 
                    selectedValue: 'TOP', 
                    sortMode: 'ASCENDING_SMART', 
                    // FILTER: Only show branches starting with 'aws-'
                    branchFilter: 'origin/(aws-.*)', 
                    tagFilter: '*', 
                    description: 'Select the Source Branch (e.g. aws-main). The job will automatically deploy to the Environment: <branch>-infra')
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
        
        stage('Checkout Code') {
            steps {
                // Checkout the selected branch (e.g., origin/aws-main)
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
                        aws configure set default.region ${AWS_REGION}
                        echo "> 🟢 [1/5] Tools Ready"
                    '''
                }
            }
        }

        stage('Fetch Configuration') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [2/5] Determining Environment Configuration..."
                        // Clean the branch name (remove 'origin/')
                        // Input: "origin/aws-main" -> Output: "aws-main"
                        def cleanBranch = params.BRANCH_NAME.replace('origin/', '')
                        
                        // MAPPING LOGIC: Map branch to environment name
                        // "aws-main" -> "aws-main-infra"
                        env.ENV_NAME = "${cleanBranch}-infra"
                        
                        // Define S3 Paths based on the mapped name
                        env.S3_METADATA_PATH = "cloud/${env.ENV_NAME}/metadata.json"
                        env.S3_KUBECONFIG_PATH = "cloud/${env.ENV_NAME}/kube-config.yaml"
                        
                        echo "============================================="
                        echo "   Selected Branch: ${cleanBranch}"
                        echo "   Target Env     : ${env.ENV_NAME}"
                        echo "   S3 Metadata    : ${env.S3_METADATA_PATH}"
                        echo "============================================="
                        
                        // Download Metadata
                        sh "aws s3 cp s3://${SECRETS_BUCKET}/${env.S3_METADATA_PATH} metadata.json"
                        
                        // Extract Secret ID & Project Name
                        env.SSH_SECRET_ID = sh(script: "jq -r '.ssh_secret_id' metadata.json", returnStdout: true).trim()
                        env.SSH_KEY_NAME = "${sh(script: "jq -r '.ssh_key_name' metadata.json", returnStdout: true).trim()}.pem"
                        env.PROJECT_NAME = sh(script: "jq -r '.project_name' metadata.json", returnStdout: true).trim()
                        
                        if (env.SSH_SECRET_ID == "null" || env.SSH_SECRET_ID == "") {
                            error "❌ [2/5] Metadata invalid: 'ssh_secret_id' missing. Is the infra provisioned for ${env.ENV_NAME}?"
                        } else {
                            echo "> 🔑 SSH Secret ID: ${env.SSH_SECRET_ID}"
                            echo "> 🗝️ SSH Key Name  : ${env.SSH_KEY_NAME}"
                            echo "> 📁 Project Name : ${env.PROJECT_NAME}"
                            echo "> 🟢 [2/5] Configuration Retrieved!"
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
                            echo "> 🔃 [3/5] Fetching SSH Key from Secrets Manager..."
                            mkdir -p keys

                            aws secretsmanager get-secret-value \
                                --secret-id ${SSH_SECRET_ID} \
                                --region ${AWS_REGION} \
                                --query SecretString \
                                --output text > keys/${SSH_KEY_NAME}

                            chmod 600 keys/${SSH_KEY_NAME}

                            if [ ! -s "keys/${SSH_KEY_NAME}" ]; then
                                echo "❌ [3/5] Error: Retrieved SSH key is empty."
                                exit 1
                            fi
                            echo "> 🟢 [3/5] SSH Key Retrieved into ${PWD}/keys!"
                        '''
                    }
                }
            }
        }

        stage('Bootstrap Cluster') {
            steps {
                ansiColor('xterm') {
                    dir("cloud/${env.ENV_NAME}/ansible") {
                        script {
                            echo "> 🔃 Running Ansible: Setup Kubernetes Cluster..."
                            
                            def status = sh(script: '''
                                chmod +x inventory/dynamic_inventory.py
                                ansible-playbook setup_cluster.yml
                            ''', returnStatus: true)
        
                            if (status != 0) {
                                echo "❌ Ansible bootstrap failed!"
                                
                                // Prompt user whether to rollback
                                def doRollback = input(
                                    message: "Bootstrap failed. Do you want to rollback the cluster?",
                                    ok: "Continue",
                                    parameters: [
                                        booleanParam(defaultValue: false, description: 'Rollback will reset nodes to clean state', name: 'ROLLBACK')
                                    ]
                                )
                                
                                if (doRollback) {
                                    echo "⚠️ Rolling back cluster..."
                                    sh '''
                                        chmod +x inventory/dynamic_inventory.py
                                        ansible-playbook rollback_cluster.yml
                                    '''
                                    error "Cluster rollback executed due to bootstrap failure."
                                } else {
                                    echo "ℹ️ User chose to skip rollback. Investigate manually."
                                }
                            } else {
                                echo "> 🟢 Cluster bootstrap completed successfully."
                            }
                        }
                    }
                }
            }
        }

        stage('Save Kubeconfig') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [5/5] Syncing Kubeconfig..."
                        
                        def localConfig = "/tmp/kubeconfig_${env.PROJECT_NAME}"
                        def s3Config = "s3_kubeconfig.yaml"
                        def finalConfig = "kube-config.yaml"
                        
                        if (fileExists(localConfig)) {
                            echo "> ✅ Ansible fetched latest config."
                            
                            // Download existing S3 version to compare
                            def s3Exit = sh(script: "aws s3 cp s3://${SECRETS_BUCKET}/${S3_KUBECONFIG_PATH} ${s3Config} --quiet", returnStatus: true)
                            
                            def uploadNeeded = false
                            
                            if (s3Exit == 0) {
                                // Compare MD5
                                def localMd5 = sh(script: "md5sum ${localConfig} | awk '{print \$1}'", returnStdout: true).trim()
                                def s3Md5 = sh(script: "md5sum ${s3Config} | awk '{print \$1}'", returnStdout: true).trim()
                                
                                echo "> 🔎 MD5 Check: Local [${localMd5}] vs S3 [${s3Md5}]"
                                
                                if (localMd5 != s3Md5) {
                                    echo "> ⚠️ Checksums differ. Update required."
                                    uploadNeeded = true
                                }
                            } else {
                                echo "> ℹ️ No existing config in S3. Initial upload."
                                uploadNeeded = true
                            }
                            
                            if (uploadNeeded) {
                                echo "> ☁️ Uploading updated config to S3..."
                                sh "aws s3 cp ${localConfig} s3://${SECRETS_BUCKET}/${S3_KUBECONFIG_PATH}"
                                echo "> ✅ Upload complete."
                            }
                            
                            sh "cp ${localConfig} ${finalConfig}"
                        } else {
                            error "❌ [5/5] Ansible did not fetch the kubeconfig."
                        }
                        
                        echo "> 🟢 [5/5] Kubeconfig Sync Complete!"
                        if (fileExists(finalConfig)) {
                            archiveArtifacts artifacts: finalConfig, allowEmptyArchive: false
                            echo "> 📁 Kubeconfig archived as build artifact."
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Cluster Setup Complete for ${env.ENV_NAME}"
        }
        failure {
            echo "❌ Cluster Setup Failed for ${env.ENV_NAME}"
        }
    }
}