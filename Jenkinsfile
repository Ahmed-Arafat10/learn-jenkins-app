pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ECS_CLUSTER = 'LearnJenkinsAppClusterProd'
        AWS_ECS_SERVICE_PROD = 'learn-jenkins-app-task-definition-prod-service-vd0czv2v'
        AWS_ECS_TD_PROD = 'learn-jenkins-app-task-definition-prod'
    }
    stages {
        stage('Build App') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                echo "=== Workspace before build ==="
                ls  -lah

                echo "=== Node & NPM versions ==="
                node -v
                npm -v

                echo "=== Installing dependencies ==="
                npm ci

                echo "=== Running build ==="
                npm run build

                echo "=== Workspace after build ==="
                ls -lah
                '''
            }
        }
        stage('Build Docker Image') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args "-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''"
                }
            }
            steps {
                sh '''
                amazon-linux-extras install docker
                docker build -t custom-nginx .
                '''
            }
        }
        stage('Deploy to AWS ECS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args "-u root --entrypoint ''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-ecs', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                    yum install -y jq
                    aws --version
                    LATEST_TD_REVISION=$(aws ecs register-task-definition --cli-input-json file://aws/task-definition-prod.json | jq '.taskDefinition.revision')

                    aws ecs update-service \
                     --service $AWS_ECS_SERVICE_PROD \
                     --task-definition $AWS_ECS_TD_PROD:$LATEST_TD_REVISION \
                     --cluster $AWS_ECS_CLUSTER

                    aws ecs wait services-stable \
                     --services $AWS_ECS_SERVICE_PROD \
                     --cluster $AWS_ECS_CLUSTER

                    echo "Deployment to AWS ECS completed successfully."
                    '''
                }
            }
        }
    }
}
