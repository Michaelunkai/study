# # multiprocessing 


# Python's multiprocessing: Concurrent execution of tasks.
# Utilizes multiple cores, improving performance.
# Shared memory enables inter-process communication.
# Processes operate independently for efficient parallelism.
# Built-in module for scalable, parallel processing.

# Multithreading involves multiple threads
# sharing the same memory space, suitable
# for I/O-bound tasks. Multiprocessing uses 
# separate memory, ideal for CPU-bound tasks.
from multiprocessing import Process, cpu_count
import time

def counter(num):
    count = 0
    while count < num:
        count += 1

def main():
    a = Process(target=counter, args=(100000000,))
    a.start()
    a.join()
    print("Finished in:", time.perf_counter(), "seconds")

if __name__ == '__main__':
    main()

# output: 
    # Finished in: 1298.185145116 seconds
    # this is the time it took my program to count ftom 0 to 100000000
