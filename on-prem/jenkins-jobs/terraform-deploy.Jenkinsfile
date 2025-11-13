pipeline {
  agent any

  environment {
    REQUIRE_APPROVAL = 'true'  // disable later for dev/qa
    // AWS Credentials
    AWS_REGION = 'ap-southeast-1'
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    // S3 Backend State files
    ON_PREM_MANAGEMENT_STATE = 'on-prem/management-terraform.tfstate'
    DEV_STATE = 'on-prem/env-dev-terraform.tfstate'
    QA_STATE = 'on-prem/env-qa-terraform.tfstate'
    // Secrets (from s3 bucket)
    SECRETS_BUCKET = 'group9-secrets-bucket'
    KUBECONFIG_DEV_FILEPATH = 'on-prem/kube-config.yaml'
    DNS_SECRETS_FILEPATH = 'on-prem/dns-record/secrets.tf'
    MANAGEMENT_SECRETS_FILEPATH = 'on-prem/management/secrets.tf'
  }

  stages {

    stage('Install Tools and Setup Secrets') {
      steps {
        sh '''
          echo "> 🔃 [1/5] Installing Terraform..."
          TERRAFORM_VERSION=1.13.5
          curl -sSL -o terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
          apt-get update
          apt-get install -y unzip
          unzip -q terraform.zip
          mv terraform /usr/local/bin/
          terraform -version
          echo "> 🟢 [1/5] Terraform Installed."

          echo "> 🔃 [2/5] Setting up Secrets..."
          echo "Installing s3cmd..."
          apt-get install -y s3cmd
          mkdir -p on-prem/cluster-configs
          echo "Downloading secrets from S3..."
          s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY get s3://$SECRETS_BUCKET/$KUBECONFIG_DEV_FILEPATH on-prem/cluster-configs/kube-config.yaml
          s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY get s3://$SECRETS_BUCKET/$MANAGEMENT_SECRETS_FILEPATH on-prem/management/secrets.tf
          s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY get s3://$SECRETS_BUCKET/$DNS_SECRETS_FILEPATH on-prem/cluster-templates/dns-record/secrets.tf
          echo "> 🟢 [2/5] Secrets are set."
        '''
      }
    }

    stage('Select Environment') {
      steps {
        script {
          // Determine environment based on branch name
          echo "> 🔍 [3/5] Detecting environment from branch name... "
          env.ENVIRONMENT = 'n/a'
          env.STATE_KEY = 'n/a'
          if (env.BRANCH_NAME == 'on-prem-management') {
            env.ENVIRONMENT = 'management'
            env.STATE_KEY = "${ON_PREM_MANAGEMENT_STATE}"
          } else if (env.BRANCH_NAME == 'dev') {
            env.ENVIRONMENT = 'dev'
            env.STATE_KEY = "${DEV_STATE}"
          } else if (env.BRANCH_NAME == 'qa') {
            env.ENVIRONMENT = 'qa'
            env.STATE_KEY = "${QA_STATE}"
          } else {
            error("🔴 Unsupported branch: ${env.BRANCH_NAME}")
          }

          echo """
          Environment Detected: ${env.ENVIRONMENT}
          Terraform State: ${env.STATE_KEY}
          """
          if (env.ENVIRONMENT != 'n/a') {
            echo "> 🟢 [3/5] Environment setup completed."
          } else {
            error("🔴 [3/5] Environment setup failed.")
          }
        }
      }
    }

    stage('Terraform Init & Plan') {
      steps {
          sh '''
            echo "> 🔃 [4/5] Running Terraform Plan for $ENVIRONMENT"
            if [[ "$ENVIRONMENT" == "management" ]]; then
                cd on-prem/management
            else
                cd on-prem/env-$ENVIRONMENT
            fi

            terraform init -backend-config="key=$STATE_KEY"
            terraform plan -out=tfplan
            echo "> 🟢 [4/5] Terraform Plan completed."
          '''
      }
    }

    stage('Manual Approval') {
      when {
        expression { env.REQUIRE_APPROVAL == 'true' }
      }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: "⚠️ Apply Terraform changes for ${env.ENVIRONMENT}?"
        }
      }
    }

    stage('Terraform Apply') {
      steps {
          sh '''
            echo "> 🔃 [5/5] Running Terraform Apply for $ENVIRONMENT"
            if [[ "$ENVIRONMENT" == "management" ]]; then
                cd on-prem/management
            else
                cd on-prem/env-$ENVIRONMENT
            fi

            terraform apply -auto-approve tfplan
            echo "> 🟢 [5/5] Terraform Apply completed."
          '''
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
