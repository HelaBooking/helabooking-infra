pipeline {
    agent any
    parameters {
        gitParameter(name: 'BRANCH_NAME', type: 'PT_BRANCH', defaultValue: 'origin/aws-main', branchFilter: 'origin/(aws-.*)')
    }
    environment {
        SECRETS_BUCKET = 'group9-secrets-bucket'
        AWS_REGION = 'ap-southeast-1'
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        ANSIBLE_CONFIG = "${WORKSPACE}/ansible/ansible.cfg"
    }
    stages {
        stage('Checkout & Metadata') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: "${params.BRANCH_NAME}"]], userRemoteConfigs: [[credentialsId: 'git-org-credentials', url: 'https://github.com/HelaBooking/helabooking-infra.git']]])
                script {
                    def cleanBranch = params.BRANCH_NAME.replace('origin/', '')
                    env.ENV_NAME = "${cleanBranch}-infra"
                    sh "aws s3 cp s3://${SECRETS_BUCKET}/cloud/${env.ENV_NAME}/metadata.json metadata.json"
                    env.SSH_SECRET_ID = sh(script: "jq -r '.ssh_secret_id' metadata.json", returnStdout: true).trim()
                    env.SSH_KEY_NAME = "${sh(script: "jq -r '.ssh_key_name' metadata.json", returnStdout: true).trim()}.pem"
                }
            }
        }
        stage('Retrieve SSH Key') {
            steps {
                dir("cloud/${env.ENV_NAME}") {
                    sh '''
                        mkdir -p keys
                        aws secretsmanager get-secret-value --secret-id ${SSH_SECRET_ID} --query SecretString --output text > keys/${SSH_KEY_NAME}
                        chmod 600 keys/${SSH_KEY_NAME}
                    '''
                }
            }
        }
        stage('VPN Setup / Status') {
            steps {
                sh "cp metadata.json cloud/${env.ENV_NAME}/metadata.json"
                dir("cloud/${env.ENV_NAME}/ansible") {
                    sh '''
                        chmod +x inventory/dynamic_inventory.py
                        # Ansible handles the "check if exists" logic inside the role
                        ansible-playbook setup_vpn.yml
                    '''
                }
            }
        }
    }
}