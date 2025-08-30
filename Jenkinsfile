pipeline {
    agent any

    stages {
        stage('Build') {
            agent{
                docker{
                    image 'node:22-alpine'
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
                    image 'node:22-alpine'
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
    }
    post{
        always{
            junit 'test-results/junit.xml'
        }
    }
}
