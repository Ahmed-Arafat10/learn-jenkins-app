pipeline {
    agent any
    stages {
        stage('Build') {
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
        stage('Test') {
            agent {
                docker {
                    image 'node:18-alpine'
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
    post {
        always {
            junit 'jest-results/junit.xml'
        }
    }
}