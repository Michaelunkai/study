# # # threading
# # # Threading in Python allows
# # # concurrent execution of tasks,
# # # improving performance by running
# # # multiple threads simultaneously 
# # # within a single process.

# # # CPU-bound: Task limited by processor speed, computation-heavy,
# # # minimal I/O operations.

# # # I/O-bound: Task constrained by input/output operations, frequent data access,
# # #  waiting for external resources.

# # import threading
# # import time
# # print(threading.active_count())
# # # output: 1

# import threading
# import time

# print(threading.active_count())
# print(threading.enumerate())
# # output : 1
# # [<_MainThread(MainThread, started 140042503404416)>]

# with multithreathing

import threading
import time

def eat_breakfast():
    time.sleep(3)
    print("you eat breakfast")

def drink_coffee():
    time.sleep(4)
    print("You drank coffee")

def study():
    time.sleep(5)
    print("You study")

print(threading.active_count())
print(threading.enumerate())

# output: 1
# [<_MainThread(MainThread, started 140313416461184)>]