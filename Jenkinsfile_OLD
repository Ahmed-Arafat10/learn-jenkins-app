pipeline {
    agent any
    environment {
        NETLIFY_SITE_ID = '10f5239f-5642-45af-a913-510d54cc28e6'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }
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
                        always {
                            junit 'jest-results/*.xml'
                        }
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
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod - Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }
        stage('Deploy To Development') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                npm install netlify-cli@20.1.1 node-jq
                node_modules/.bin/netlify --version
                echo "Deploying to development, Site ID : $NETLIFY_SITE_ID"
                node_modules/.bin/netlify status
                node_modules/.bin/netlify deploy --dir=build --json > deploy-dev-output.json
                '''
                script {
                    env.NETLIFY_DEV_URL = sh(script: "node_modules/.bin/node-jq -r '.deploy_url' deploy-dev-output.json", returnStdout: true)
                }
            }
        }
        stage('Development E2E Test') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = "${env.NETLIFY_DEV_URL}"
            }
            steps {
                sh '''
                        node_modules/.bin/serve -s build &
                        ls
                        sleep 10
                        npx playwright test --reporter=html
                   '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Dev - Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
        stage('Approve To Deploy Production'){
            steps {
                timeout(time: 1, unit: 'MINUTES'){
                    input message: 'Do you wish to deploy to production', ok: 'Yes, iam sure'
                }
            }
        }
        stage('Deploy To Production') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                echo "Deploying to production, Site ID : $NETLIFY_SITE_ID"
                node_modules/.bin/netlify status
                node_modules/.bin/netlify deploy --dir=build --prod
                '''
            }
        }
        stage('Production E2E Test') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'https://jenkins-cd.netlify.app/'
            }
            steps {
                sh '''
                        node_modules/.bin/serve -s build &
                        ls
                        sleep 10
                        npx playwright test --reporter=html
                      '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod - Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}
