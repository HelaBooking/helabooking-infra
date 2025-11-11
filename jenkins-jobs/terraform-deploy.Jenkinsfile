pipeline {
  agent any

  environment {
    REQUIRE_APPROVAL = 'true'  // disable later for dev/qa
    // AWS Credentials
    AWS_CREDS_REGION = 'ap-southeast-1'
    AWS_CREDS_ACCESS_KEY_ID = credentials('aws-access-key-id')
    AWS_CREDS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    AWS_CREDS_SESSION_TOKEN = credentials('aws-session-token')
    // S3 Backend State files
    ON_PREM_MANAGEMENT_STATE = 'on-prem/management-terraform.tfstate'
    DEV_STATE = 'on-prem/env-dev-terraform.tfstate'
    QA_STATE = 'on-prem/env-qa-terraform.tfstate'
    // Cluster Kubeconfig paths
    ON_PREM_CLUSTER_KUBECONFIG = 'cluster-configs/kube-config.yaml'
  }

  stages {

    stage('Install Terraform & Setup AWS Credentials') {
      steps {
        sh '''
          echo "> Installing Terraform..."
          TERRAFORM_VERSION=1.13.5
          curl -sSL -o https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
          unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
          sudo mv terraform /usr/local/bin/
          terraform -version

          echo "> Setting up AWS credentials..."
          export AWS_REGION=${AWS_CREDS_REGION}
          export AWS_ACCESS_KEY_ID=${AWS_CREDS_ACCESS_KEY_ID}
          export AWS_SECRET_ACCESS_KEY=${AWS_CREDS_SECRET_ACCESS_KEY}
          export AWS_SESSION_TOKEN=${AWS_CREDS_SESSION_TOKEN}
          echo "AWS credentials set!"
        '''
      }
    }

    stage('Select Environment') {
      steps {
        script {
          // Determine environment based on branch name
          if (env.BRANCH_NAME == 'on-prem-management') {
            env.ENVIRONMENT = 'management'
            env.STATE_KEY = "${ON_PREM_MANAGEMENT_STATE}"
            env.KUBECONFIG_FILE = "${ON_PREM_CLUSTER_KUBECONFIG}"
          } else if (env.BRANCH_NAME == 'dev') {
            env.ENVIRONMENT = 'dev'
            env.STATE_KEY = "${DEV_STATE}"
            env.KUBECONFIG_FILE = "${ON_PREM_CLUSTER_KUBECONFIG}"
          } else if (env.BRANCH_NAME == 'qa') {
            env.ENVIRONMENT = 'qa'
            env.STATE_KEY = "${QA_STATE}"
            env.KUBECONFIG_FILE = "${ON_PREM_CLUSTER_KUBECONFIG}"
          } else {
            error("Unsupported branch: ${env.BRANCH_NAME}")
          }

          echo """
          Environment Detected: ${env.ENVIRONMENT}
          Terraform State: ${env.STATE_KEY}
          Kubeconfig: ${env.KUBECONFIG_FILE}
          """
        }
      }
    }

    stage('Terraform Init & Plan') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            echo "> Running Terraform Plan for $ENVIRONMENT"
            if [[ "$ENVIRONMENT" == "management" ]]; then
                cd on-prem/management
            else
                cd on-prem/env-$ENVIRONMENT
            fi

            terraform init -backend-config="key=$STATE_KEY"
            terraform plan -var="kubeconfig_path=$KUBECONFIG_FILE" -out=tfplan
          '''
        }
      }
    }

    stage('Manual Approval') {
      when {
        expression { env.REQUIRE_APPROVAL == 'true' }
      }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: "Apply Terraform changes for ${env.ENVIRONMENT}?"
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            echo "> Running Terraform Apply for $ENVIRONMENT"
            if [[ "$ENVIRONMENT" == "management" ]]; then
                cd on-prem/management
            else
                cd on-prem/env-$ENVIRONMENT
            fi

            terraform apply -auto-approve tfplan
          '''
        }
      }
    }
  }

  // Show success/failure message
  post {
    success {
      echo "Terraform deployment to ${env.ENVIRONMENT} completed successfully."
    }
    failure {
      echo "Terraform deployment to ${env.ENVIRONMENT} failed."
    }
  }
}
