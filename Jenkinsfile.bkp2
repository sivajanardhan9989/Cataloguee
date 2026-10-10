pipeline {
    agent {
        node {
            label 'ROBOSHOP'
        }
    }

    environment {
        ACC_ID      = '209115427888'
        PROJECT     = 'roboshop'
        COMPONENT   = 'catalogue'
        AWS_REGION  = 'us-east-1'
    }

    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Read Version') {
            steps {
                script {
                    def config = readJSON file: 'package.json'
                    def version = config.version?.toString()?.trim()

                    if (!version) {
                        error 'Version is missing or empty in package.json'
                    }

                    env.APP_VERSION = version
                    echo "Application version: ${version}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -eu
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
                            set -eu

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
                    def config = readJSON file: 'package.json'
                    def version = config.version?.toString()?.trim()

                    if (!version) {
                        error 'Version is missing from package.json'
                    }

                    env.APP_VERSION = version

                    def image = "${env.ACC_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.PROJECT}/${env.COMPONENT}:${version}"

                    echo "Building Docker image: ${image}"

                    sh """
                        set -eu
                        docker build -t '${image}' .
                    """
                }
            }
        }

        /*
        stage('Trivy Image Scan') {
            steps {
                script {
                    def config = readJSON file: 'package.json'
                    def version = config.version?.toString()?.trim()

                    if (!version) {
                        error 'Version is missing. Cannot scan Docker image.'
                    }

                    def image = "${env.ACC_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.PROJECT}/${env.COMPONENT}:${version}"

                    echo "Scanning Docker image: ${image}"

                    sh """
                        set -eu

                        trivy image \
                          --severity HIGH,CRITICAL \
                          --exit-code 1 \
                          --no-progress \
                          '${image}'
                    """
                }
            }
        }
        */

        stage('Docker Push') {
            steps {
                script {
                    def config = readJSON file: 'package.json'
                    def version = config.version?.toString()?.trim()

                    if (!version) {
                        error 'Version is missing. Cannot push Docker image.'
                    }

                    def registry = "${env.ACC_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                    def image = "${registry}/${env.PROJECT}/${env.COMPONENT}:${version}"

                    withAWS(
                        credentials: 'aws-creds',
                        region: 'us-east-1'
                    ) {
                        sh """
                            set -eu

                            echo "Logging in to Amazon ECR"

                            aws ecr get-login-password \
                              --region '${env.AWS_REGION}' | \
                              docker login \
                                --username AWS \
                                --password-stdin '${registry}'

                            echo "Pushing Docker image: ${image}"

                            docker push '${image}'
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                def config = readJSON file: 'package.json'
                echo "Catalogue pipeline completed successfully. Version: ${config.version}"
            }
        }

        failure {
            echo 'Catalogue pipeline failed. Check the Jenkins console output.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}
