pipeline {
  agent any

  triggers {
    pollSCM('H/5 * * * *')
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    NEXUS_URL      = 'http://127.0.0.1:8081'
    NEXUS_REPO     = 'terraform-artifacts'
    SONAR_PROJECT  = 'terraform-infra'
    TF_VERSION     = '1.7.5'
    ARTIFACT_NAME  = "terraform-infra-${BUILD_NUMBER}.tar.gz"
  }

  stages {

    stage('Checkout') {
      steps {
        git credentialsId: 'git-credentials',
            url: 'git@github.com:srikar2011/terraform-infra.git',
            branch: 'main'
      }
    }

    stage('Install Terraform') {
      steps {
        sh '''
          if ! terraform version 2>/dev/null | grep -q ${TF_VERSION}; then
            wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
            unzip -o terraform_${TF_VERSION}_linux_amd64.zip
            sudo mv terraform /usr/local/bin/
            rm -f terraform_${TF_VERSION}_linux_amd64.zip
          fi
          terraform version
        '''
      }
    }

    stage('Terraform Validate') {
      steps {
        sh '''
          terraform init -backend=false
          terraform validate
          terraform fmt -check -recursive
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh '''
            sonar-scanner \
              -Dsonar.projectKey=${SONAR_PROJECT} \
              -Dsonar.sources=. \
              -Dsonar.exclusions=**/.terraform/**,*.tfstate* \
              -Dsonar.projectVersion=${BUILD_NUMBER}
          '''
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

    stage('Package Artifact') {
      steps {
        sh '''
          rm -rf .terraform .terraform.lock.hcl *.tfstate *.tfstate.backup
          tar -czf ${ARTIFACT_NAME} \
            --exclude='.git' \
            --exclude='.sonarqube' \
            --exclude='Jenkinsfile' \
            .
          echo "Package created: ${ARTIFACT_NAME}"
          ls -lh ${ARTIFACT_NAME}
        '''
      }
    }

    stage('Push to Nexus') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'nexus-credentials',
          usernameVariable: 'NEXUS_USER',
          passwordVariable: 'NEXUS_PASS')]) {
          sh '''
            curl -v -u ${NEXUS_USER}:${NEXUS_PASS} \
              --upload-file ${ARTIFACT_NAME} \
              ${NEXUS_URL}/repository/${NEXUS_REPO}/${ARTIFACT_NAME}
            echo "Artifact pushed to Nexus: ${NEXUS_REPO}/${ARTIFACT_NAME}"
          '''
        }
      }
    }

  }

  post {
    success {
      echo "Terraform artifact ${ARTIFACT_NAME} built and published to Nexus successfully!"
    }
    failure {
      echo "Build failed. Check SonarQube Quality Gate or Terraform validation."
    }
    always {
      cleanWs()
    }
  }
}
