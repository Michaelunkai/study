# Set permissions for a folder
$folderPath = "C:\"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain\User", "FullControl", "Allow")
$acl = Get-Acl $folderPath
$acl.SetAccessRule($rule)
Set-Acl $folderPath $acl
