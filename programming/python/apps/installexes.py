import os
import subprocess

def install_executables():
    # Get the current script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # List all files in the script's directory
    files = os.listdir(script_dir)

    # Filter out only executable files (ending with .exe)
    exe_files = [file for file in files if file.lower().endswith('.exe')]

    # Install each executable file
    for exe_file in exe_files:
        exe_path = os.path.join(script_dir, exe_file)
        
        # Run the installation command
        subprocess.run([exe_path])

if __name__ == "__main__":
    install_executables()
