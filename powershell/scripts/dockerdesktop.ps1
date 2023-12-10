[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe -OutFile DockerDesktopInstaller.exe
Start-Process -Wait -FilePath .\DockerDesktopInstaller.exe
Remove-Item -Path .\DockerDesktopInstaller.exe
