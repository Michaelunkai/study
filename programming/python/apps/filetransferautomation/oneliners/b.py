import os
import shutil
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time

class MyHandler(FileSystemEventHandler):
    def on_any_event(self, event):
        if event.is_directory:
            return
        if event.event_type in ('created', 'modified'):
            self.copy_last_file()

    def copy_last_file(self):
        path = "."  # Replace with the directory you want to monitor
        files = [os.path.join(path, f) for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
        if not files:
            return
        latest_file = max(files, key=os.path.getctime)
        destination = "/mnt/c/study/automation/oneliners"
        shutil.copy(latest_file, destination)

def main():
    path = "."  # Replace this with the directory you want to monitor
    event_handler = MyHandler()
    observer = Observer()
    observer.schedule(event_handler, path, recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    main()
