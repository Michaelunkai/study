# daemon threads

# Daemon threads run in the background.
# Automatically exit when main ends.
# Non-daemon threads block program exit.
# Used for tasks like garbage collection.
# Set with setDaemon(True).

import threading
import time

def timer():
    print()
    count = 0 
    while True:
        time.sleep(1)
        count += 1
        print("logged in for: ".count, "seconds")



answer = input("Do you wish to exit?")