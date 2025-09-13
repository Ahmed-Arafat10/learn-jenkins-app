pipeline {
    agent any
    stages {
        /*stage('Build') {
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
        }*/
        stage('Run Tests') {
            parallel {
                stage('Unit Test') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                #test -f build/index.html
                npm test
                '''
                    }
                    post {
                        junit 'jest-results/*.xml'
                    }
                }
                stage('E2E') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                npm install serve
                node_modules/.bin/serve -s build &
                ls
                sleep 10
                npx playwright test --reporter=html
                '''
                    }
                    always {
                        publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                    }
                }
            }
        }
    }
}
