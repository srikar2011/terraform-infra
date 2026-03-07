<powershell>
# Enable WinRM for Chef/SSM
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Enable firewall rules for WinRM
netsh advfirewall firewall add rule name="WinRM HTTP" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in localport=5986 action=allow

# Install SSM Agent
$ssmAgentUrl = "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe"
$installer = "C:\Windows\Temp\SSMAgentSetup.exe"
try {
  Invoke-WebRequest -Uri $ssmAgentUrl -OutFile $installer -UseBasicParsing
  Start-Process -FilePath $installer -ArgumentList "/S" -Wait
  Remove-Item $installer -Force
} catch {
  Write-Host "SSM Agent already installed or download failed"
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Chef Infra Client
choco install chef-client -y --no-progress

# Install AWS CLI
choco install awscli -y --no-progress

Write-Host "Bootstrap complete for environment: ${environment}"
</powershell>