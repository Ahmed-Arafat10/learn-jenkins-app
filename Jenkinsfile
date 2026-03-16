pipeline {
    agent any
    environment {
        REACT_APP_VERSION = "1.0.$BUILD_NUMBER"
        APP_NAME = 'practice-jenkins-ecs-ecr-app'
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ECS_CLUSTER = 'LearnJenkinsAppClusterProd'
        AWS_ECS_SERVICE_PROD = 'learn-jenkins-app-task-definition-prod-service-vd0czv2v'
        AWS_ECS_TD_PROD = 'learn-jenkins-app-task-definition-prod'
        AWS_DOCKER_REGISTRY = '508261693782.dkr.ecr.us-east-1.amazonaws.com'
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
                    image 'custom-aws-cli'
                    reuseNode true
                    args "-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-ecr', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                    docker build -t $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION .
                    aws ecr get-login-password | docker login \
                    --username AWS \
                    --password-stdin \
                    $AWS_DOCKER_REGISTRY
                    docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION
                    '''
                }
            }
        }
        stage('Deploy to AWS ECS') {
            agent {
                docker {
                    image 'custom-aws-cli'
                    reuseNode true
                    args "--entrypoint ''"  //root not needed here
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-ecs', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                    aws --version
                    sed -i "s|#APP_VERSION#|$REACT_APP_VERSION|g" aws/task-definition-prod.json
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
