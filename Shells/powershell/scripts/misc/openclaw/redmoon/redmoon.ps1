# Quick access function for red moon wallpapers
# Add this to your PowerShell profile for easy access

function redmoon {
    param(
        [string]$Action = "help"
    )
    
    $managerScript = "C:\Users\micha\.openclaw\workspace\scripts\red-moon-wallpaper-manager.ps1"
    
    switch ($Action.ToLower()) {
        "help" {
            Write-Host ""
            Write-Host "Red Moon Wallpaper Commands:" -ForegroundColor Red
            Write-Host "  redmoon         - Open wallpaper manager menu"
            Write-Host "  redmoon random  - Set random red moon wallpaper" 
            Write-Host "  redmoon list    - List all wallpapers"
            Write-Host "  redmoon rotate  - Enable hourly rotation"
            Write-Host "  redmoon folder  - Open wallpaper folder"
            Write-Host ""
        }
        "random" {
            & "C:\Users\micha\.openclaw\workspace\scripts\rotate-red-moon-wallpapers.ps1"
        }
        "list" {
            & $managerScript -Action "list"
        }
        "rotate" {
            & "C:\Users\micha\.openclaw\workspace\scripts\rotate-red-moon-wallpapers.ps1" -AutoSchedule
        }
        "folder" {
            Start-Process explorer.exe -ArgumentList "$env:USERPROFILE\Pictures\Wallpapers\RedMoon"
        }
        default {
            & $managerScript
        }
    }
}

# Add alias for quick access
Set-Alias -Name rm-wall -Value redmoon

# Loaded silently (use 'redmoon help' for commands)