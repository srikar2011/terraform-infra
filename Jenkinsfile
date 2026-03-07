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
    NEXUS_URL     = 'http://127.0.0.1:8081'
    NEXUS_REPO    = 'terraform-artifacts'
    SONAR_PROJECT = 'terraform-infra'
    TF_VERSION    = '1.7.5'
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
        powershell '''
          $tfPath = "C:\\tools\\terraform"

          # Add to PATH for this session
          $env:PATH = "$tfPath;$env:PATH"

          # Check if already installed
          try {
            $installed = & "$tfPath\\terraform.exe" version 2>$null
            if ($installed -match $env:TF_VERSION) {
              Write-Host "Terraform $env:TF_VERSION already installed - skipping"
              exit 0
            }
          } catch {}

          Write-Host "Installing Terraform $env:TF_VERSION..."
          New-Item -ItemType Directory -Force -Path $tfPath | Out-Null

          $url = "https://releases.hashicorp.com/terraform/$env:TF_VERSION/terraform_$($env:TF_VERSION)_windows_amd64.zip"
          Write-Host "Downloading from: $url"

          Invoke-WebRequest -Uri $url -OutFile "$tfPath\\terraform.zip" -UseBasicParsing
          Expand-Archive -Path "$tfPath\\terraform.zip" -DestinationPath $tfPath -Force
          Remove-Item "$tfPath\\terraform.zip" -Force

          # Add to system PATH permanently
          $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
          if ($machinePath -notlike "*$tfPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$machinePath;$tfPath", "Machine")
            Write-Host "Added Terraform to system PATH"
          }

          Write-Host "Terraform installed successfully"
          & "$tfPath\\terraform.exe" version
          if ($LASTEXITCODE -ne 0) { exit 1 }
        '''
      }
    }

    stage('Terraform Validate') {
      steps {
        powershell '''
          $env:PATH = "C:\\tools\\terraform;$env:PATH"

          Write-Host "Running terraform init..."
          terraform init -backend=false
          if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: terraform init failed"
            exit 1
          }

          Write-Host "Running terraform validate..."
          terraform validate
          if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: terraform validate failed"
            exit 1
          }

          Write-Host "Running terraform fmt check..."
          terraform fmt -check -recursive
          if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: terraform fmt check failed - run terraform fmt to fix formatting"
            exit 1
          }

          Write-Host "All Terraform validations passed"
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          powershell '''
            $env:PATH = "C:\\tools\\sonar-scanner\\bin;$env:PATH"

            Write-Host "Running SonarQube analysis..."
            Write-Host "Project: $env:SONAR_PROJECT"
            Write-Host "Build: $env:BUILD_NUMBER"

            sonar-scanner.bat `
              "-Dsonar.projectKey=$env:SONAR_PROJECT" `
              "-Dsonar.projectName=Terraform Infrastructure" `
              "-Dsonar.sources=." `
              "-Dsonar.exclusions=**/.terraform/**,*.tfstate*,**/*.tfvars" `
              "-Dsonar.projectVersion=$env:BUILD_NUMBER"

            if ($LASTEXITCODE -ne 0) {
              Write-Host "ERROR: SonarQube analysis failed"
              exit 1
            }
            Write-Host "SonarQube analysis complete"
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
        powershell '''
          Write-Host "Cleaning Terraform temp files..."
          Remove-Item -Recurse -Force ".terraform"       -ErrorAction SilentlyContinue
          Remove-Item -Force ".terraform.lock.hcl"       -ErrorAction SilentlyContinue
          Remove-Item -Force "*.tfstate"                 -ErrorAction SilentlyContinue
          Remove-Item -Force "*.tfstate.backup"          -ErrorAction SilentlyContinue
          Remove-Item -Force "artifact_name.txt"         -ErrorAction SilentlyContinue

          $artifactName = "terraform-infra-$env:BUILD_NUMBER.tar.gz"
          Write-Host "Creating package: $artifactName"

          tar -czf $artifactName `
            --exclude=".git" `
            --exclude=".sonarqube" `
            --exclude="Jenkinsfile" `
            --exclude="artifact_name.txt" `
            .

          if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Failed to create artifact package"
            exit 1
          }

          $sizeKB = [math]::Round((Get-Item $artifactName).Length / 1KB, 2)
          Write-Host "Package created: $artifactName ($sizeKB KB)"

          # Save artifact name for Push stage
          $artifactName | Out-File -FilePath "artifact_name.txt" -Encoding UTF8 -NoNewline
        '''
      }
    }

    stage('Push to Nexus') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'nexus-credentials',
          usernameVariable: 'NEXUS_USER',
          passwordVariable: 'NEXUS_PASS')]) {
          powershell '''
            $artifactName = (Get-Content "artifact_name.txt" -Raw).Trim()
            $url = "$env:NEXUS_URL/repository/$env:NEXUS_REPO/$artifactName"

            Write-Host "Uploading artifact: $artifactName"
            Write-Host "Nexus URL: $url"

            curl.exe -s -w "\nHTTP Status: %{http_code}\n" `
              -u "$env:NEXUS_USER`:$env:NEXUS_PASS" `
              --upload-file $artifactName `
              $url

            if ($LASTEXITCODE -ne 0) {
              Write-Host "ERROR: Upload to Nexus failed!"
              exit 1
            }
            Write-Host "Successfully uploaded to Nexus: $url"
          '''
        }
      }
    }

  }

  post {
    success {
      slackSend(
        channel: env.SLACK_CHANNEL,
        color: 'good',
        message: """
  :white_check_mark: *BUILD SUCCESS* - Terraform
  *Job:* ${env.JOB_NAME}
  *Build:* #${env.BUILD_NUMBER}
  *Duration:* ${currentBuild.durationString}
  *Artifact:* terraform-infra-${env.BUILD_NUMBER}.tar.gz pushed to Nexus
  *URL:* ${env.BUILD_URL}
        """.trim()
      )
    }
    failure {
      slackSend(
        channel: env.SLACK_CHANNEL,
        color: 'danger',
        message: """
  :x: *BUILD FAILED* - Terraform
  *Job:* ${env.JOB_NAME}
  *Build:* #${env.BUILD_NUMBER}
  *Duration:* ${currentBuild.durationString}
  *URL:* ${env.BUILD_URL}console
        """.trim()
      )
    }
    unstable {
      slackSend(
        channel: env.SLACK_CHANNEL,
        color: 'warning',
        message: """
  :warning: *BUILD UNSTABLE* - Terraform
  *Job:* ${env.JOB_NAME}
  *Build:* #${env.BUILD_NUMBER}
  *URL:* ${env.BUILD_URL}
        """.trim()
      )
    }
    always {
      cleanWs()
    }
  }
}
