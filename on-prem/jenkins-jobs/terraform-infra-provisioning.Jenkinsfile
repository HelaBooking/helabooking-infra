pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        TERRAFORM_VERSION = '1.13.5' 
        REQUIRE_APPROVAL = 'true'

        // AWS Credentials
        AWS_REGION = 'ap-southeast-1'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        
        // S3 Buckets
        STATE_BUCKET = 'group9-terraform-state-bucket'
        SECRETS_BUCKET = 'group9-secrets-bucket'
    }

    stages {
        
        stage('Initialize Environment') {
            steps {
                script {
                    // Logic to map Branch Name -> Folder Path & Environment Name
                    env.ENV_NAME = "${env.BRANCH_NAME}-infra"
                    env.TERRAFORM_DIRECTORY = "cloud/${env.BRANCH_NAME}-infra"
                    env.S3_METADATA_PATH = "cloud/${env.ENV_NAME}/metadata.json"
                    
                    echo "🚀 Provisioning Environment: ${env.ENV_NAME}"
                    echo "📂 Terraform Directory: ${env.TERRAFORM_DIRECTORY}"
                }
            }
        }

        stage('Install Tools') {
            steps {
                ansiColor('xterm') {
                    sh '''
                        echo "> 🔃 [1/6] Installing Dependencies..."
                        # System Tools (AWS CLI, jq, s3cmd)
                        apt-get update && apt-get install -y unzip curl jq awscli
                        echo "> 🟢 [1/6] Dependencies are installed!"
                        
                        echo "> 🔃 [2/6] Installing Terraform..."
                        # Terraform
                        if ! command -v terraform >/dev/null 2>&1 || [ "$(terraform version -json | jq -r .terraform_version)" != "$TERRAFORM_VERSION" ]; then
                            curl -sSL -o terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                            unzip -o -q terraform.zip   # -o = overwrite without prompting
                            mv -f terraform /usr/local/bin/
                            terraform -version
                            echo "> 🟢 [2/6] Terraform Installed."
                        else
                            echo "> 🟢 [2/6] Terraform $TERRAFORM_VERSION already installed."
                        fi

                        echo "> 🔃 [3/6] Configuring AWS CLI..."
                        # AWS CLI Configuration
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile default
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile default
                        aws configure set region $AWS_REGION --profile default
                        echo "> 🟢 [3/6] AWS CLI Configured!"
                    '''
                }
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                ansiColor('xterm') {
                    script{
                        echo "> 🔃 [4/6] Running Terraform Plan for $ENV_NAME"

                        def planExitCode = sh(script: """
                        cd ${env.TERRAFORM_DIRECTORY}
                        terraform init
                        terraform plan -out=tfplan -detailed-exitcode
                        """, returnStatus: true)

                        echo "> 🟢 [4/6] Terraform Plan completed."
                        env.PLAN_EXIT_CODE = planExitCode.toString()
                        
                        if (env.PLAN_EXIT_CODE == '0') {
                            echo "> ℹ️ No changes detected in Terraform plan. Skipping Apply stage."
                        }
                    }
                }
            }
        }

        stage('Manual Approval') {
            when {
                expression { env.REQUIRE_APPROVAL == 'true' && env.PLAN_EXIT_CODE == '2'}
            }
            steps {
                script {
                    ansiColor('xterm') {
                        try {
                            timeout(time: 20, unit: 'MINUTES') {
                                input message: "⚠️ Apply Terraform changes for ${env.ENV_NAME}?"
                            }
                        } catch(err) {
                            echo "⚠️ Deployment aborted or timeout reached. Skipping Terraform Apply."
                            currentBuild.result = 'ABORTED'
                            // Optionally, stop the pipeline here
                            return
                        }   
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { currentBuild.result != 'ABORTED' && env.PLAN_EXIT_CODE == '0' }
            }
            steps {
                ansiColor('xterm') {
                sh '''
                    echo "> 🔃 [5/6] Running Terraform Apply for ${ENV_NAME}"
                    cd ${TERRAFORM_DIRECTORY}
                    terraform apply -auto-approve tfplan
                    echo "> 🟢 [5/6] Terraform Apply completed."
                    rm -f tfplan
                '''
                }
            }
        }

        stage('Save Artifacts') {
            steps {
                ansiColor('xterm') {
                    script {
                        echo "> 🔃 [6/6] Regenerating Artifacts from State..."
                        
                        // REGENERATE FILES: This ensures files exist even if 'Apply' was skipped
                        sh """
                            cd ${env.TERRAFORM_DIRECTORY}
                            
                            # Generate metadata.json
                            terraform output -raw metadata_json > metadata.json
                            
                            # Parse Key Path using jq
                            KEY_PATH=\$(jq -r '.ssh_key_local_path' metadata.json)
                            
                            # Save the path to a text file so Jenkins can read it later
                            echo -n "\$KEY_PATH" > ssh_key_path.txt
                            
                            # Create directory and generate the .pem file
                            mkdir -p \$(dirname \$KEY_PATH)
                            terraform output -raw ssh_private_key_pem > \$KEY_PATH
                            chmod 600 \$KEY_PATH
                            
                            echo "> ✅ Artifacts regenerated from Terraform State."
                            
                            # Upload Metadata to S3
                            echo "> Uploading metadata.json to S3..."
                            aws s3 cp metadata.json s3://${env.SECRETS_BUCKET}/${env.S3_METADATA_PATH}
                            echo "> Metadata uploaded to s3://${env.SECRETS_BUCKET}/${env.S3_METADATA_PATH}"
                        """

                        // Read the file to get the path for archiving
                        dir("${env.TERRAFORM_DIRECTORY}") {
                            if (fileExists("ssh_key_path.txt")) {
                                // Read the path string from the text file we just created
                                def keyPath = readFile("ssh_key_path.txt").trim()
                                
                                echo "> Saving SSH Key Artifact from path: ${keyPath}"
                                
                                if (fileExists(keyPath)) {
                                    archiveArtifacts artifacts: keyPath, allowEmptyArchive: false
                                    echo "> 🟢 [6/6] All Artifacts Saved."
                                } else {
                                    error "❌ [6/6] Generated key file not found at: ${keyPath}"
                                }
                            } else {
                                error "❌ [6/6] Failed to determine SSH key path (ssh_key_path.txt missing)"
                            }
                        }
                    }   
                }
            }
        }
    }
    
    // Show success or failure message
    post {
        success {
            echo "✅ Terraform deployment to ${env.ENV_NAME} completed successfully."
            echo "> Download the SSH Private Key from Jenkins Job Artifacts."
        }
        failure {
            echo "❌ Terraform deployment to ${env.ENV_NAME} failed!"
        }
    }
}