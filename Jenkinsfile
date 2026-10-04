pipeline {
    agent {
        node {
            label 'ROBOSHOP'
        }
    }

    environment {
        acc_id = "209115427888"
        project = "roboshop"
        component = "catalogue"
        appVersion = ""
    }

    options {
        disableConcurrentBuilds()
        timeout(time: 15, unit: 'MINUTES')
    }

    stages {

        stage('Read Version') {
            steps {
                script {
                    def config = readJSON file: 'package.json'
                    appVersion = config.version

                    echo "The application version is: ${appVersion}"
                }
            }
        }

        stage('Install dependencies') {
            steps {
                sh '''
                    npm install
                '''
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    // Get AWS authentication
                    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                        sh """
                            aws ecr get-login-password --region us-east-1 | \
                            docker login --username AWS --password-stdin \
                            ${acc_id}.dkr.ecr.us-east-1.amazonaws.com

                            docker build -t \
                            ${acc_id}.dkr.ecr.us-east-1.amazonaws.com/${project}/${component}:${appVersion} \
                            .
                        """
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                        sh """
                            docker push \
                            ${acc_id}.dkr.ecr.us-east-1.amazonaws.com/${project}/${component}:${appVersion}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'I will always say Hello again!'
        }

        success {
            echo 'I will run when success'
        }

        failure {
            echo 'I will run when it is failed'
        }
    }
}

// http://23.22.226.61:8080/