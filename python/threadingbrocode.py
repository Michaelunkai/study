# threading
# Threading in Python allows
# concurrent execution of tasks,
# improving performance by running
# multiple threads simultaneously 
# within a single process.

# CPU-bound: Task limited by processor speed, computation-heavy,
# minimal I/O operations.

# I/O-bound: Task constrained by input/output operations, frequent data access,
#  waiting for external resources.

import threading
import time
print(threading.active_count())
# output: 1