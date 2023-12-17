# Create a backup of the entire C: drive using robocopy
$backupPath = "C:\windowsbackup"
$sourcePath = "C:\"
$robocopyOptions = "/MIR /COPYALL /R:2 /W:5 /LOG+:$backupPath\robocopy.log"

# Run robocopy to copy the entire C: drive to the backup location
Start-Process robocopy -ArgumentList "$sourcePath $backupPath $robocopyOptions" -Wait -NoNewWindow
