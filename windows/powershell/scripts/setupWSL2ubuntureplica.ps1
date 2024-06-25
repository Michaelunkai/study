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
wsl -d $newDistroName -u root usermod -l $username ubuntu

# Update the new distro
wsl -d $newDistroName -u $username bash -c "sudo apt update && sudo apt upgrade -y"

# Remove the tarball
Remove-Item $env:TEMP\ubuntu.tar
