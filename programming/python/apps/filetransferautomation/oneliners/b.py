import os
import shutil
import time

def get_latest_file(directory):
    latest_file = None
    latest_time = -1
    
    for root, dirs, files in os.walk(directory):
        for name in files:
            filepath = os.path.join(root, name)
            file_time = os.path.getctime(filepath)
            if file_time > latest_time:
                latest_time = file_time
                latest_file = filepath
                
    return latest_file

def copy_latest_file(source_directory, destination_directory):
    if not os.path.exists(destination_directory):
        os.makedirs(destination_directory)
        
    latest_file = get_latest_file(source_directory)
    
    if latest_file:
        destination_file = os.path.join(destination_directory, os.path.basename(latest_file))
        shutil.copy2(latest_file, destination_file)
        print(f"Copied {latest_file} to {destination_file}")
    else:
        print("No files found in the source directory.")

if __name__ == "__main__":
    source_dir = "/mnt/c/study/"
    destination_dir = "/mnt/c/study/automation/oneliners"
    
    copy_latest_file(source_dir, destination_dir)
