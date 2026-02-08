pipeline {
    agent any
    environment {
        // Note: Netfliy check for env variable called NETLIFY_SITE_ID to identify the site, so we need to use that name
        NETLIFY_SITE_ID = '4c33091d-a993-4563-90be-7aeb971edbbd'
        // Note: Netfliy check for env variable called NETLIFY_AUTH_TOKEN to authonticate, so we need to use that name
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }
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
                    npm install netlify-cli
                    node_modules/.bin/netlify --version
                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
                    node_modules/.bin/netlify status
                    node_modules/.bin/netlify deploy --dir=build
                '''
            }
        }
        // stage('Deploy') {
        //     agent {
        //         docker {
        //             image 'node:18-alpine'
        //             reuseNode true
        //         }
        //     }
        //     steps {
        //         sh '''
        //         npm install netlify-cli
        //         ./node_modules/.bin/netlify --version
        //         echo "Deploying to Netlify, Site ID: ${NETLIFY_SITE_ID}"
        //         ./node_modules/.bin/netlify status
        //         ls -lah
        //         ./node_modules/.bin/netlify deploy \
        //         --prod \
        //         --dir=build \
        //         --no-build \
        //         --site $NETLIFY_SITE_ID \
        //         --auth $NETLIFY_AUTH_TOKEN \
        //         --json > deploy-output.json
        //         '''
        //     }
        // }
        // stage('Prod (E2E) Test') {
        //             agent {
        //                 docker {
        //                     // any other version will not work
        //                     image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
        //                     reuseNode true
        //                 }
        //             }
        //             environment {
        //                 CI_ENVIRONMENT_URL = 'https://jenkins26-cicd.netlify.app'
        //             }
        //             steps {
        //                 sh '''
        //                 npx playwright test --reporter=html
        //                 '''
        //             }
        //             post {
        //                 always {
        //                     publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod - Playwright HTML Report', reportTitles: 'Prod - Playwright HTML Report', useWrapperFileDirectly: true])
        //                 }
        //             }
        // }
    }
}
