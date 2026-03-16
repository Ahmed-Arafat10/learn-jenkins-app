pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['prod'], description: 'Deployment environment')
    }

    environment {
        REACT_APP_VERSION = "1.0.${BUILD_NUMBER}"
        APP_NAME = 'practice-jenkins-ecs-ecr-app'

        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_DOCKER_REGISTRY = '508261693782.dkr.ecr.us-east-1.amazonaws.com'

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
                ls -lah

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

        stage('Build & Push Docker Image') {
            agent {
                docker {
                    image 'custom-aws-cli'
                    reuseNode true
                    args "-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''"
                }
            }

            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    sh '''
                    echo "=== Logging into AWS ECR ==="
                    aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login \
                        --username AWS \
                        --password-stdin \
                        $AWS_DOCKER_REGISTRY

                    echo "=== Building Docker image ==="
                    docker build -t $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION .

                    echo "=== Tagging image as latest ==="
                    docker tag \
                      $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION \
                      $AWS_DOCKER_REGISTRY/$APP_NAME:latest

                    echo "=== Pushing version tag ==="
                    docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION

                    echo "=== Pushing latest tag ==="
                    docker push $AWS_DOCKER_REGISTRY/$APP_NAME:latest
                    '''
                }
            }
        }

        stage('Deploy to AWS ECS') {
            agent {
                docker {
                    image 'custom-aws-cli'
                    reuseNode true
                    args "--entrypoint ''"
                }
            }

            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecs',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    sh '''
                    echo "=== AWS CLI Version ==="
                    aws --version

                    echo "=== Updating task definition with new image version ==="
                    sed -i "s|#APP_VERSION#|$REACT_APP_VERSION|g" aws/task-definition-prod.json

                    echo "=== Registering new ECS task definition ==="
                    LATEST_TD_REVISION=$(aws ecs register-task-definition \
                        --cli-input-json file://aws/task-definition-prod.json \
                        | jq '.taskDefinition.revision')

                    echo "New revision: $LATEST_TD_REVISION"

                    echo "=== Updating ECS service ==="
                    aws ecs update-service \
                        --cluster $AWS_ECS_CLUSTER \
                        --service $AWS_ECS_SERVICE_PROD \
                        --task-definition $AWS_ECS_TD_PROD:$LATEST_TD_REVISION

                    echo "=== Waiting for service stability ==="
                    aws ecs wait services-stable \
                        --cluster $AWS_ECS_CLUSTER \
                        --services $AWS_ECS_SERVICE_PROD

                    echo "Deployment completed successfully."
                    '''
                }
            }
        }
    }

    post {

        success {
            echo "Pipeline completed successfully 🚀"
        }

        failure {
            echo "Pipeline failed ❌"
        }

        always {

            echo "Cleaning workspace and Docker artifacts..."

            sh '''
            docker image prune -f || true
            '''

            cleanWs()
        }
    }
}