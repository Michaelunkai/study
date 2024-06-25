# Set the name of the new distro
$newDistroName = "ubuntu2"

# Set the path to store the new distro
$newDistroPath = "C:\wsl2\$newDistroName"

# Set the username for the new distro
$username = "ubu2"

# Export the existing distro to a tarball
wsl --export Ubuntu $env:TEMP\ubuntu.tar

# Create the new distro from the tarball
wsl --import $newDistroName $newDistroPath $env:TEMP\ubuntu.tar

# Set the default user for the new distro
wsl -d $newDistroName usermod -s /bin/bash $username
wsl -d $newDistroName chsh -s /bin/bash $username

# Update the new distro
wsl -d $newDistroName apt update
wsl -d $newDistroName apt upgrade -y

# Remove the tarball
Remove-Item $env:TEMP\ubuntu.tar
