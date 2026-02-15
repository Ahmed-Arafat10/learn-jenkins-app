pipeline {
    agent any
    environment {
        // Note: Netfliy check for env variable called NETLIFY_SITE_ID to identify the site, so we need to use that name
        NETLIFY_SITE_ID = credentials('netlify-site-id')
        // Note: Netfliy check for env variable called NETLIFY_AUTH_TOKEN to authonticate, so we need to use that name
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID" // Example of using Jenkins build number as part of app version
    }
    stages {
        stage('Notify Start') {
            steps {
                script {
                    slackSend(
                        channel: '#jenkins',
                        color: '#439FE0',
                        message: "🚀 Build Started!\n" +
                                 "Job: ${env.JOB_NAME}\n" +
                                 "Build ID: ${env.BUILD_ID}\n" +
                                 "Build Number: ${env.BUILD_NUMBER}\n" +
                                 "Triggered By: ${currentBuild.getBuildCauses()[0]?.shortDescription}"
                    )
                }
            }
        }

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

                    echo "Installing dependencies with cache"
                    npm ci --cache .npm --prefer-offline

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
                        npx serve -s build &
                        npx wait-on http://localhost:3000
                        npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: 'Playwright HTML Report', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }
        stage('Deploy In Staging') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npx netlify --version
                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
                    npx netlify status
                    npx netlify deploy \
                    --dir=build \
                    --no-build \
                    --site $NETLIFY_SITE_ID \
                    --auth $NETLIFY_AUTH_TOKEN \
                    --json > netlify-deploy-stage.json
                '''
                script {
                    env.NETLIFY_STAGE_URL = sh(script: "npx node-jq -r '.deploy_url' netlify-deploy-stage.json", returnStdout: true).trim()
                }
            }
        }
        stage('Staging E2E Test') {
                agent {
                    docker {
                        // any other version will not work
                        image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                        reuseNode true
                    }
                }
                environment {
                    CI_ENVIRONMENT_URL = "${env.NETLIFY_STAGE_URL}"
                }
                steps {
                    sh '''
                    npx playwright test --reporter=html
                    '''
                }
                post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Staging E2E Test', reportTitles: '', useWrapperFileDirectly: true])
                }
                }
        }
        stage('Deploy Production') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                npx netlify --version
                echo "Deploying to Netlify, Site ID: ${NETLIFY_SITE_ID}"
                npx netlify status
                ls -lah
                npx netlify deploy \
                --prod \
                --dir=build \
                --no-build \
                --site $NETLIFY_SITE_ID \
                --auth $NETLIFY_AUTH_TOKEN \
                --json > netlify-deploy-prod.json
                '''
                script {
                    env.NETLIFY_PROD_URL = sh(script: "npx node-jq -r '.url' netlify-deploy-prod.json", returnStdout: true).trim()
                }
            }
        }
        stage('Prod (E2E) Test') {
                    agent {
                        docker {
                            // any other version will not work
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
                    environment {
                        CI_ENVIRONMENT_URL = "${env.NETLIFY_PROD_URL}"
                    }
                    steps {
                        sh '''
                        npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod - Playwright HTML Report', reportTitles: 'Prod - Playwright HTML Report', useWrapperFileDirectly: true])
                        }
                    }
        }
    }
    post {
        success {
            slackSend(
            channel: '#jenkins',
            color: 'good',
            message: "✅ Production deployed successfully: ${env.NETLIFY_PROD_URL}"
        )
        }
        failure {
            slackSend(
            channel: '#jenkins',
            color: 'danger',
            message: "❌ Production deployment FAILED in job ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
        }
    }
}
