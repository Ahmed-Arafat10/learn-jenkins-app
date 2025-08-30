pipeline {
    agent any
    
    environment {
        DOCKER_NODE_IMG = "node:18-alpine"
    }

    stages {
        stage('Build') {
            agent{
                docker{
                    image "${DOCKER_NODE_IMG}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                ls -la
                node -v
                npm -v
                npm ci
                npm run build
                ls -la
                '''
            }
        }
        stage('Testing') {
            agent{
                docker{
                    image "${DOCKER_NODE_IMG}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    test -f build/index.html
                    npm test
                '''
            }
        }
        stage('E2E'){
            agent {
                docker{
                    image 'mcr.microsoft.com/playwright:v1.43.0-focal'
                }
            }
            steps {
                sh ```
                npm install serve
                node_modules/.bin/serve -s build &
                sleep 10
                npx playwright test
                ```
            }
        }
    }
    post {
        always {
            junit 'test-results/junit.xml'
        }
    }
}
