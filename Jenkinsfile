pipeline {
    agent {
        docker {
            image 'my-playwright'
            reuseNode true
        }
    }
    environment {
        // Note: Netfliy check for env variable called NETLIFY_SITE_ID to identify the site, so we need to use that name
        NETLIFY_SITE_ID = credentials('netlify-site-id')
        // Note: Netfliy check for env variable called NETLIFY_AUTH_TOKEN to authonticate, so we need to use that name
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID" // Example of using Jenkins build number as part of app version
    }
    stages {
        // build in mightly jenkins pipeline, but not in main pipeline, because we want to build the docker image only once a day, and use it for all the builds in that day
        // stage('Docker') {
        //     steps {
        //         sh 'docker build -t my-playwright .'
        //     }
        // }
        stage('Build') {
            
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
}
