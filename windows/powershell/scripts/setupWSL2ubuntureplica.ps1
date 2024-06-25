# Set the name of the new distro
$newDistroName = "ubuntu2"

# Set the path to store the new distro
$newDistroPath = "C:\wsl2\$newDistroName"

# Set the username for the new distro
$username = "ubu2"

# Function to restart the LxssManager service (WSL service)
function Restart-WSLService {
    Write-Host "Restarting WSL service..."
    Stop-Service -Name "LxssManager" -Force
    Start-Service -Name "LxssManager"
}

# Restart the WSL service
Restart-WSLService

# Unregister the existing distro if it exists
if (wsl -l -v | Select-String -Pattern $newDistroName) {
    wsl --unregister $newDistroName
}

# Ensure no WSL processes are running
wsl --terminate Ubuntu
Stop-Process -Name "wsl" -Force -ErrorAction SilentlyContinue

# Remove any existing files from previous attempts
if (Test-Path $newDistroPath) {
    Remove-Item -Recurse -Force $newDistroPath
}

# Export the existing distro to a tarball
Write-Host "Exporting current Ubuntu distro..."
wsl --export Ubuntu $env:TEMP\ubuntu.tar

# Wait a moment to ensure the tarball is fully created
Start-Sleep -Seconds 5

# Create the new distro from the tarball
Write-Host "Importing new Ubuntu distro..."
wsl --import $newDistroName $newDistroPath $env:TEMP\ubuntu.tar

# Check if the distro is successfully imported
if (wsl -l -v | Select-String -Pattern $newDistroName) {
    Write-Host "Setting up new Ubuntu distro..."
    # Set the default user for the new distro
    wsl -d $newDistroName -u root useradd -m -s /bin/bash $username
    wsl -d $newDistroName -u root usermod -aG sudo $username

    # Update the new distro
    wsl -d $newDistroName -u $username bash -c "sudo apt update && sudo apt upgrade -y"

    # Remove the tarball
    Remove-Item $env:TEMP\ubuntu.tar
    Write-Host "New Ubuntu distro setup completed successfully."
} else {
    Write-Host "Failed to import the new distribution."
}
