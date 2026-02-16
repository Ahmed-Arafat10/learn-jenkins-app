pipeline {
    agent {
        docker {
            image 'my-playwright'
            reuseNode true
            args '-v $HOME/.npm:/root/.npm'
        }
    }

    options {
        durabilityHint('PERFORMANCE_OPTIMIZED')
    }

    environment {
        NETLIFY_SITE_ID = credentials('netlify-site-id')
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID"
    }

    stages {

        stage('Build') {
            steps {
                sh '''
                    echo "=== Node & NPM versions ==="
                    node --version
                    npm --version

                    echo "Installing dependencies (cached)"
                    npm ci --prefer-offline

                    echo "=== Running build ==="
                    npm run build
                '''
            }
        }

        stage('Tests') {
            parallel {

                stage('Unit Test') {
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
                    steps {
                        sh '''
                            npx serve -s build -l 3000 &
                            npx wait-on http://localhost:3000 --timeout 30000
                            npx playwright test --workers=4 --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Playwright HTML Report',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
            }
        }

        stage('Deploy In Staging') {
            steps {
                sh '''
                    echo "Deploying to staging..."
                    npx netlify deploy \
                        --yes \
                        --dir=build \
                        --no-build \
                        --site $NETLIFY_SITE_ID \
                        --auth $NETLIFY_AUTH_TOKEN \
                        --json > netlify-deploy-stage.json
                '''
                script {
                    env.NETLIFY_STAGE_URL = sh(
                        script: "npx node-jq -r '.deploy_url' netlify-deploy-stage.json",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Staging E2E Test') {
            environment {
                CI_ENVIRONMENT_URL = "${env.NETLIFY_STAGE_URL}"
            }
            steps {
                sh '''
                    npx playwright test --workers=4 --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Staging E2E Test',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }

        stage('Deploy Production') {
            steps {
                sh '''
                    echo "Deploying to production..."
                    npx netlify deploy \
                        --yes \
                        --prod \
                        --dir=build \
                        --no-build \
                        --site $NETLIFY_SITE_ID \
                        --auth $NETLIFY_AUTH_TOKEN \
                        --json > netlify-deploy-prod.json
                '''
                script {
                    env.NETLIFY_PROD_URL = sh(
                        script: "npx node-jq -r '.url' netlify-deploy-prod.json",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Prod (E2E) Test') {
            environment {
                CI_ENVIRONMENT_URL = "${env.NETLIFY_PROD_URL}"
            }
            steps {
                sh '''
                    npx playwright test --workers=4 --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Prod - Playwright HTML Report',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
    }
}
