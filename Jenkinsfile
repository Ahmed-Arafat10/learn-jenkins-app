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
                ls -a
                node -v
                npm -v
                npm ci
                npm run build
                '''
            }
        }
    }
}
