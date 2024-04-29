import subprocess
import ctypes
import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QCheckBox, QPushButton
from PyQt5.QtGui import QFont

def run_command_as_admin(command):
    try:
        if sys.platform.startswith('win'):
            # Check if the script is running as admin
            if ctypes.windll.shell32.IsUserAnAdmin() != 0:
                subprocess.run(["powershell", "-Command", command, "; exit"], shell=True, check=True)
            else:
                ctypes.windll.shell32.ShellExecuteW(None, "runas", "powershell", "-Command " + command + "; exit", None, 1)
    except Exception as e:
        print("Error:", e)

def run_selected_commands():
    selected_commands = []
    for cmd, var in zip(commands, command_vars):
        if var.isChecked():
            selected_commands.append(cmd["command"])

    command_to_run = "; ".join(selected_commands)
    run_command_as_admin(command_to_run)

def choose_all():
    for var in command_vars:
        var.setChecked(True)

if __name__ == "__main__":
    # List of commands with brief names
    commands = [
        {"name": "Update choco Packages", "command": "choco upgrade all -y --force"},
        {"name": "Scan System Health", "command": "Repair-WindowsImage -Online -ScanHealth"},
        {"name": "Restore System Health", "command": "Repair-WindowsImage -Online -RestoreHealth"},
        {"name": "Check System Files", "command": "sfc /scannow"},
        {"name": "Check Image Health", "command": "DISM.exe /Online /Cleanup-Image /CheckHealth"},
        {"name": "Restore Image Health", "command": "DISM.exe /Online /Cleanup-Image /RestoreHealth"},
        {"name": "Cleanup Component Store", "command": "dism /online /cleanup-image /startcomponentcleanup"},
        {"name": "Check Disk Errors", "command": "chkdsk /f /r"},
        {"name": "Start Update Service", "command": "net start wuauserv"},
        {"name": "windows updates", "command": "Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope CurrentUser; Get-WindowsUpdate -Install -AcceptAll -Verbose"},
        {"name": "Defragment C Drive", "command": "defrag C: /U /V"},
        {"name": "Reset TCP/IP Stack", "command": "netsh int ip reset"},
        {"name": "Reset Winsock", "command": "netsh winsock reset"},
        {"name": "Analyze Component Store", "command": "dism /online /cleanup-image /analyzecomponentstore"},
        {"name": "Cleanup Component Store", "command": "dism /online /cleanup-image /startcomponentcleanup"},
        {"name": "Flush DNS Cache", "command": "ipconfig /flushdns"},
        {"name": "Clear Application Log", "command": "wevtutil cl Application"},
        {"name": "Clear Security Log", "command": "wevtutil cl Security"},
        {"name": "Clear System Log", "command": "wevtutil cl System"},
        {"name": "Clear DNS Cache", "command": "Clear-DnsClientCache"},
        {"name": "Re-register AppX Packages", "command": "Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\\AppXManifest.xml\"}"},
        {"name": "Start Defender Scan", "command": "Start-MpScan -ScanType QuickScan"},
        {"name": "Unregister Kali WSL", "command": "wsl --unregister kali-linux"},
        {"name": "Import Kali WSL", "command": "wsl --import kali-linux C:\\wsl2 C:\\backup\\linux\\wsl\\kalifull.tar"},
        {"name": "Unregister Ubuntu WSL", "command": "wsl --unregister ubuntu"},
        {"name": "Import Ubuntu WSL", "command": "wsl --import ubuntu C:\\wsl2\\ubuntu\\ C:\\backup\\linux\\wsl\\ubuntu.tar"}
    ]

    app = QApplication(sys.argv)
    root = QWidget()
    root.setWindowTitle("Select Commands to Run")
    root.setStyleSheet("background-color: #f5f5dc;")
    root.showMaximized()  # Open in full-screen mode
    layout = QVBoxLayout(root)

    command_vars = []
    for cmd in commands:
        checkbox = QCheckBox(cmd['name'], parent=root)
        checkbox.setFont(QFont("Lobster", 10, QFont.Bold))
        layout.addWidget(checkbox)
        command_vars.append(checkbox)

    choose_all_button = QPushButton("Choose All", parent=root)
    choose_all_button.clicked.connect(choose_all)
    choose_all_button.setStyleSheet("background-color: black; color: white; font-weight: bold;")
    layout.addWidget(choose_all_button)

    run_button = QPushButton("Run Selected Commands", parent=root)
    run_button.clicked.connect(run_selected_commands)
    run_button.setStyleSheet("background-color: black; color: white; font-weight: bold;")
    layout.addWidget(run_button)

    root.setLayout(layout)
    sys.exit(app.exec_())
