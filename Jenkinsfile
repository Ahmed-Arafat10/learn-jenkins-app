pipeline {
    agent any
    environment {
        REACT_APP_VERSION = "1.0.$BUILD_NUMBER"
        APP_NAME = 'practice-jenkins-ecs-ecr-app'
        AWS_S3_BUCKET = 'learn-jenkins-2026-arafat'
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
          stage('AWS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args '--entrypoint=""'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-s3', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                sh '''
                aws --version
                aws s3 ls
                # echo "Hello S3" > index.html
                # aws s3 cp index.html s3://$AWS_S3_BUCKET/index.html
                aws s3 sync build s3://$AWS_S3_BUCKET
                '''
                }
            }
        }

    }
}
