pipeline {
    agent {
        node {
            label 'ROBOSHOP'
        }
    }

    environment {
        ACC_ID    = "209115427888"
        PROJECT   = "roboshop"
        COMPONENT = "catalogue"
        APP_VERSION = ""
        AWS_REGION = "us-east-1"
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

                    if (!config.version?.toString()?.trim()) {
                        error "Version is missing or empty in package.json"
                    }

                    env.APP_VERSION = config.version.toString()

                    echo "Application version: ${env.APP_VERSION}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -e
                    npm install
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('sonar-server') {
                        sh """
                            set -e

                            "${scannerHome}/bin/sonar-scanner" \
                              -Dsonar.projectKey=Roboshop-catalogue \
                              -Dsonar.projectName=Roboshop-catalogue \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions=node_modules/**,coverage/**,.git/**
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        def qualityGate = waitForQualityGate(
                            abortPipeline: true
                        )

                        echo "SonarQube Quality Gate: ${qualityGate.status}"
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    withAWS(
                        credentials: 'aws-creds',
                        region: "${AWS_REGION}"
                    ) {
                        sh '''
                            set -e

                            IMAGE="${ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT}/${COMPONENT}:${APP_VERSION}"

                            echo "Building Docker image: ${IMAGE}"

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
                        region: "${AWS_REGION}"
                    ) {
                        sh '''
                            set -e

                            REPOSITORY="${ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT}/${COMPONENT}"
                            IMAGE="${REPOSITORY}:${APP_VERSION}"

                            echo "Logging in to Amazon ECR"

                            aws ecr get-login-password \
                              --region "${AWS_REGION}" | \
                              docker login \
                                --username AWS \
                                --password-stdin \
                                "${ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                            echo "Pushing Docker image: ${IMAGE}"

                            docker push "${IMAGE}"
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Catalogue pipeline completed successfully."
            echo "Application version: ${env.APP_VERSION}"
        }

        failure {
            echo "Catalogue pipeline failed. Check the Jenkins console output."
        }

        always {
            echo "Pipeline execution finished."
        }
    }
}
