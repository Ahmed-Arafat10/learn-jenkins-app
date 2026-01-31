pipeline {
    agent any

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    // not required
                    // args '-u root:root' // run as root to avoid permission issues
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo "=== Workspace before build ==="
                    ls -lah

                    echo "=== Node & NPM versions ==="
                    node --version
                    npm --version

                    echo "=== Installing dependencies ==="
                    npm ci

                    echo "=== Running build ==="
                    npm run build

                    echo "=== Workspace after build ==="
                    ls -lah
                '''
            }
        }
        stage('Tests') {
            parallel {
                stage('Unit Test') {
                    agent {
                        docker {
                            //Note: not same node version as above
                            image 'node:14-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                        test -f build/index.html
                        npm test
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }
                stage('End-to-End (E2E) Test') {
                    agent {
                        docker {
                            // any other version will not work
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                        npm install serve
                        node_modules/.bin/serve -s build &
                        sleep 10
                        npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }
    }
}
