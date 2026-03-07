pipeline {
  agent any

  options {
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  parameters {
    string(name: 'TF_ARTIFACT_BUILD',   defaultValue: 'latest', description: 'Terraform build number or latest')
    string(name: 'CHEF_ARTIFACT_BUILD', defaultValue: 'latest', description: 'Chef build number or latest')
    choice(name: 'ENVIRONMENT',         choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    booleanParam(name: 'APPLY_TERRAFORM', defaultValue: true,  description: 'Run terraform apply?')
    booleanParam(name: 'RUN_CHEF',        defaultValue: true,  description: 'Run Chef configuration?')
    booleanParam(name: 'DESTROY',         defaultValue: false, description: 'Destroy infrastructure?')
  }

  environment {
    NEXUS_URL            = 'http://127.0.0.1:8081'
    TF_REPO              = 'terraform-artifacts'
    CHEF_REPO            = 'chef-artifacts'
    AWS_REGION           = 'us-east-1'
    TF_VAR_environment   = "${params.ENVIRONMENT}"
    TF_VAR_vpc_id        = 'vpc-XXXXXXXX'
    TF_VAR_subnet_ids    = '["subnet-AAAA","subnet-BBBB"]'
    TF_VAR_ec2_subnet_id = 'subnet-AAAA'
    TF_VAR_key_pair_name = 'your-ec2-key-pair'
    TF_VAR_app_name      = 'mywebapp'
  }

  stages {

    stage('Download Artifacts from Nexus') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'nexus-credentials',
          usernameVariable: 'NEXUS_USER',
          passwordVariable: 'NEXUS_PASS')]) {
          powershell '''
            New-Item -ItemType Directory -Force -Path "terraform"
            New-Item -ItemType Directory -Force -Path "chef"

            # Download Terraform artifact
            if ($env:TF_ARTIFACT_BUILD -eq "latest") {
              $response = Invoke-RestMethod `
                -Uri "$env:NEXUS_URL/service/rest/v1/components?repository=$env:TF_REPO" `
                -Credential (New-Object PSCredential($env:NEXUS_USER,
                  (ConvertTo-SecureString $env:NEXUS_PASS -AsPlainText -Force)))
              $tfFile = ($response.items | Sort-Object version -Descending |
                Select-Object -First 1).assets[0].path.Split("/")[-1]
            } else {
              $tfFile = "terraform-infra-$env:TF_ARTIFACT_BUILD.tar.gz"
            }

            Write-Host "Downloading Terraform artifact: $tfFile"
            curl.exe -s -u "$env:NEXUS_USER`:$env:NEXUS_PASS" `
              -o "terraform\\$tfFile" `
              "$env:NEXUS_URL/repository/$env:TF_REPO/$tfFile"
            tar -xzf "terraform\\$tfFile" -C terraform/
            Write-Host "Terraform artifact extracted"

            # Download Chef artifact
            if ($env:CHEF_ARTIFACT_BUILD -eq "latest") {
              $response = Invoke-RestMethod `
                -Uri "$env:NEXUS_URL/service/rest/v1/components?repository=$env:CHEF_REPO" `
                -Credential (New-Object PSCredential($env:NEXUS_USER,
                  (ConvertTo-SecureString $env:NEXUS_PASS -AsPlainText -Force)))
              $chefFile = ($response.items | Sort-Object version -Descending |
                Select-Object -First 1).assets[0].path.Split("/")[-1]
            } else {
              $chefFile = "chef-config-$env:CHEF_ARTIFACT_BUILD.tar.gz"
            }

            Write-Host "Downloading Chef artifact: $chefFile"
            curl.exe -s -u "$env:NEXUS_USER`:$env:NEXUS_PASS" `
              -o "chef\\$chefFile" `
              "$env:NEXUS_URL/repository/$env:CHEF_REPO/$chefFile"
            tar -xzf "chef\\$chefFile" -C chef/
            Write-Host "Chef artifact extracted"
          '''
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-credentials']]) {
          powershell '''
            $env:PATH += ";C:\\tools\\terraform"
            Set-Location terraform
            terraform init
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            $ws = $env:ENVIRONMENT
            terraform workspace select $ws
            if ($LASTEXITCODE -ne 0) {
              terraform workspace new $ws
            }
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-credentials']]) {
          powershell '''
            $env:PATH += ";C:\\tools\\terraform"
            Set-Location terraform
            terraform plan `
              -var="environment=$env:ENVIRONMENT" `
              -out=tfplan
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            Write-Host "Terraform plan complete"
          '''
        }
      }
    }

    stage('Approval Gate') {
      when {
        expression { return params.ENVIRONMENT == 'prod' }
      }
      steps {
        input message: 'Approve deployment to PRODUCTION?',
              ok: 'Deploy to Prod',
              submitter: 'admin'
      }
    }

    stage('Terraform Apply or Destroy') {
      when {
        expression { return params.APPLY_TERRAFORM }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-credentials']]) {
          powershell '''
            $env:PATH += ";C:\\tools\\terraform"
            Set-Location terraform

            if ($env:DESTROY -eq "true") {
              terraform destroy -auto-approve `
                -var="environment=$env:ENVIRONMENT"
            } else {
              terraform apply -auto-approve tfplan
              if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
              terraform output -json | Out-File -FilePath "..\tf_outputs.json" -Encoding UTF8
              Write-Host "Terraform apply complete"
              Get-Content "..\tf_outputs.json"
            }
          '''
        }
      }
    }

    stage('Wait for EC2 Bootstrap') {
      when {
        expression { return params.APPLY_TERRAFORM && !params.DESTROY }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-credentials']]) {
          powershell '''
            $outputs = Get-Content "tf_outputs.json" | ConvertFrom-Json
            $ec2Id = $outputs.ec2_instance_id.value
            Write-Host "Waiting for EC2 $ec2Id to pass status checks..."

            aws ec2 wait instance-status-ok `
              --instance-ids $ec2Id `
              --region $env:AWS_REGION

            Write-Host "EC2 ready - waiting 60s for WinRM bootstrap..."
            Start-Sleep -Seconds 60
          '''
        }
      }
    }

    stage('Chef Configuration') {
      when {
        expression { return params.RUN_CHEF && !params.DESTROY }
      }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-credentials']]) {
          powershell '''
            $outputs = Get-Content "tf_outputs.json" | ConvertFrom-Json
            $ec2Id = $outputs.ec2_instance_id.value
            $ec2Ip = $outputs.ec2_private_ip.value
            Write-Host "Running Chef on EC2 $ec2Id at $ec2Ip"

            # Upload cookbooks to S3
            aws s3 cp chef\\cookbooks s3://YOUR-S3-BUCKET/chef/cookbooks `
              --recursive --region $env:AWS_REGION
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

            # Run chef-client via SSM
            $commandId = aws ssm send-command `
              --document-name "AWS-RunPowerShellScript" `
              --targets "Key=instanceids,Values=$ec2Id" `
              --parameters commands=["aws s3 cp s3://YOUR-S3-BUCKET/chef/cookbooks C:/chef/cookbooks --recursive; chef-client --local-mode -o webserver --chef-license accept"] `
              --region $env:AWS_REGION `
              --output text `
              --query Command.CommandId

            Write-Host "SSM Command ID: $commandId"

            # Wait for completion
            aws ssm wait command-executed `
              --command-id $commandId `
              --instance-id $ec2Id `
              --region $env:AWS_REGION

            if ($LASTEXITCODE -ne 0) {
              Write-Host "Chef run failed!"
              exit $LASTEXITCODE
            }
            Write-Host "Chef configuration complete"
          '''
        }
      }
    }

    stage('Verify Deployment') {
      when {
        expression { return !params.DESTROY }
      }
      steps {
        powershell '''
          $outputs = Get-Content "tf_outputs.json" | ConvertFrom-Json
          $albDns = $outputs.alb_dns_name.value
          Write-Host "Testing health check at http://$albDns/health"
          Start-Sleep -Seconds 30

          $success = $false
          for ($i = 1; $i -le 5; $i++) {
            try {
              $response = Invoke-WebRequest `
                -Uri "http://$albDns/health" `
                -UseBasicParsing `
                -TimeoutSec 10
              Write-Host "Attempt $i`: HTTP Status = $($response.StatusCode)"
              if ($response.StatusCode -eq 200) {
                Write-Host "SUCCESS: Application healthy at http://$albDns"
                $success = $true
                break
              }
            } catch {
              Write-Host "Attempt $i`: Failed - $($_.Exception.Message)"
            }
            Start-Sleep -Seconds 20
          }

          if (-not $success) {
            Write-Host "WARN: Health check did not return 200 after 5 attempts"
          }
        '''
      }
    }

  }

  post {
    success {
      echo "Deployment complete! Infrastructure and configuration applied."
    }
    failure {
      echo "Deployment failed. Check logs above."
    }
    always {
      cleanWs()
    }
  }
}