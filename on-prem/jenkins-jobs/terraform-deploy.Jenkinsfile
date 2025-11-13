pipeline {
  agent any

  environment {
    REQUIRE_APPROVAL = 'true'  // disable later for dev/qa
    // AWS Credentials
    AWS_REGION = 'ap-southeast-1'
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    // Secrets (from s3 bucket)
    SECRETS_BUCKET = 'group9-secrets-bucket'
    KUBECONFIG_DEV_FILEPATH = 'on-prem/kube-config.yaml'
    DNS_SECRETS_FILEPATH = 'on-prem/dns-record/secrets.tf'
    MANAGEMENT_SECRETS_FILEPATH = 'on-prem/management/secrets.tf'
  }

  stages {

    stage('Install Tools and Setup Secrets') {
      steps {
        ansiColor('xterm') {
          sh '''
            echo "> 🔃 [1/5] Installing Terraform..."
            TERRAFORM_VERSION=1.13.5
            apt-get update && apt-get install -y unzip jq
            if ! command -v terraform >/dev/null 2>&1 || [ "$(terraform version -json | jq -r .terraform_version)" != "$TERRAFORM_VERSION" ]; then
                curl -sSL -o terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                unzip -o -q terraform.zip   # -o = overwrite without prompting
                mv -f terraform /usr/local/bin/
                terraform -version
                echo "> 🟢 [1/5] Terraform Installed."
            else
                echo "> 🟢 [1/5] Terraform $TERRAFORM_VERSION already installed."
            fi

            echo "> 🔃 [2/5] Setting up Secrets..."
            echo "Installing s3cmd..."
            apt-get install -y s3cmd
            if [ ! -d "on-prem/cluster-configs" ]; then
              mkdir -p on-prem/cluster-configs
            fi
            echo "Downloading secrets from S3..."
            s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --force get s3://$SECRETS_BUCKET/$KUBECONFIG_DEV_FILEPATH on-prem/cluster-configs/kube-config.yaml
            s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --force get s3://$SECRETS_BUCKET/$MANAGEMENT_SECRETS_FILEPATH on-prem/management/secrets.tf
            s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --force get s3://$SECRETS_BUCKET/$DNS_SECRETS_FILEPATH on-prem/cluster-templates/dns-record/secrets.tf
            echo "> 🟢 [2/5] Secrets are set."
          '''
        }
      }
    }

    stage('Select Environment') {
      steps {
        script {
          ansiColor('xterm') {
            // Determine environment based on branch name
            echo "> 🔍 [3/5] Detecting environment from branch name... "
            env.ENVIRONMENT = 'n/a'
            if (env.BRANCH_NAME == 'on-prem-management') {
              env.ENVIRONMENT = 'management'
            } else if (env.BRANCH_NAME == 'dev') {
              env.ENVIRONMENT = 'dev'
            } else if (env.BRANCH_NAME == 'qa') {
              env.ENVIRONMENT = 'qa'
            } else {
              error("🔴 Unsupported branch: ${env.BRANCH_NAME}")
            }

            echo """
            Environment Detected: ${env.ENVIRONMENT}
            """
            if (env.ENVIRONMENT != 'n/a') {
              echo "> 🟢 [3/5] Environment setup completed."
            } else {
              error("🔴 [3/5] Environment setup failed.")
              // Optionally, stop the pipeline here
              return
            }
          }
        }
      }
    }

    stage('Terraform Init & Plan') {
      steps {
        ansiColor('xterm') {
          script{
            echo "> 🔃 [4/5] Running Terraform Plan for $ENVIRONMENT"

            def planExitCode = sh(script: """
            if [ "$ENVIRONMENT" == "management" ]; then
                cd on-prem/management
            else
                cd on-prem/env-$ENVIRONMENT
            fi

            terraform init
            terraform plan -out=tfplan -detailed-exitcode
            """, returnStatus: true)
            echo "> 🟢 [4/5] Terraform Plan completed."
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
              timeout(time: 15, unit: 'MINUTES') {
                input message: "⚠️ Apply Terraform changes for ${env.ENVIRONMENT}?"
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
        expression { currentBuild.result != 'ABORTED' }
      }
      steps {
        ansiColor('xterm') {
          sh '''
            echo "> 🔃 [5/5] Running Terraform Apply for $ENVIRONMENT"
            if [ "$ENVIRONMENT" == "management" ]; then
                cd on-prem/management
            else
                cd on-prem/env-$ENVIRONMENT
            fi

            terraform apply -auto-approve tfplan
            echo "> 🟢 [5/5] Terraform Apply completed."
            rm -f tfplan
          '''
        }
      }
    }
  }

  // Show success/failure message
  post {
    success {
      echo "✅ Terraform deployment to ${env.ENVIRONMENT} completed successfully."
    }
    failure {
      echo "❌ Terraform deployment to ${env.ENVIRONMENT} failed!"
    }
  }
}
