
pipeline {
    agent {
        node {
            label 'ROBOSHOP'
        }
    }

    environment {
        ACC_ID = "209115427888"
        PROJECT = "roboshop"
        COMPONENT = "catalogue"
        APP_VERSION = ""
    }

    options {
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {

        stage('Read Version') {
            steps {
                script {
                    def config = readJSON file: 'package.json'
                    env.APP_VERSION = config.version.toString()

                    echo "The application version is: ${env.APP_VERSION}"
                }
            }
        }

        stage('Install dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('sonar-server') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=Roboshop-catalogue \
                              -Dsonar.projectName=Roboshop-catalogue \
                              -Dsonar.sources=.
                        """
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    withAWS(
                        credentials: 'aws-creds',
                        region: 'us-east-1'
                    ) {
                        sh '''
                            set -eu

                            IMAGE="${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT}/${COMPONENT}:${APP_VERSION}"

                            aws ecr get-login-password --region us-east-1 |
                                docker login \
                                    --username AWS \
                                    --password-stdin \
                                    "${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com"

                            docker build -t "${IMAGE}" .
                        '''
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    withAWS(
                        credentials: 'aws-creds',
                        region: 'us-east-1'
                    ) {
                        sh '''
                            set -eu

                            IMAGE="${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT}/${COMPONENT}:${APP_VERSION}"

                            docker push "${IMAGE}"
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution finished.'
        }

        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the Console Output.'
        }
    }
}
