pipeline {
    agent {
        node {
            label 'ROBOSHOP'
        }
    }

    environment {
        ACC_ID     = '209115427888'
        PROJECT    = 'roboshop'
        COMPONENT  = 'catalogue'
        AWS_REGION = 'us-east-1'
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

        stage('Check Dependabot Alerts') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'github-token',
                        variable: 'GH_TOKEN'
                    )
                ]) {
                    sh '''
                        set -eu

                        REPO="sivajanardhan9989/Cataloguee"
                        API_URL="https://api.github.com/repos/${REPO}/dependabot/alerts?state=open&per_page=100"

                        curl --fail --silent --show-error --location \
                            -H "Accept: application/vnd.github+json" \
                            -H "Authorization: Bearer ${GH_TOKEN}" \
                            -H "X-GitHub-Api-Version: 2022-11-28" \
                            "${API_URL}" \
                            -o alerts.json

                        echo "---- Open Dependabot Alerts ----"

                        jq -r '.[] |
                            "\\(.number)\\t\\(.security_vulnerability.severity)\\t\\(.dependency.package.name)\\t\\(.security_advisory.ghsa_id)"' \
                            alerts.json

                        HIGH_CRITICAL_COUNT=$(jq \
                            '[.[] | select(
                                .security_vulnerability.severity == "high" or
                                .security_vulnerability.severity == "critical"
                            )] | length' alerts.json)

                        echo "High/Critical alert count: ${HIGH_CRITICAL_COUNT}"

                        if [ "${HIGH_CRITICAL_COUNT}" -gt 0 ]; then
                            echo "High/Critical Dependabot alerts found. Failing build."
                            exit 1
                        fi

                        echo "No High/Critical alerts found."
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('sonar-server') {
                        sh """
                            set -eu
                            "\${scannerHome}/bin/sonar-scanner" \
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
                        def qualityGate =
                            waitForQualityGate(abortPipeline: true)

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
