import os
import psutil

def get_disk_space(path='.'):
    if not path:
        path = '.'

    usage = psutil.disk_usage(path)
    total_space_gb = usage.total / (2 ** 30)
    used_space_gb = usage.used / (2 ** 30)
    free_space_gb = usage.free / (2 ** 30)

    return total_space_gb, used_space_gb, free_space_gb

def get_largest_files(path='.', num_files=5):
    if not path:
        path = '.'

    try:
        file_sizes = [(f, os.path.getsize(os.path.join(path, f))) for root, dirs, files in os.walk(path) for f in files]
        sorted_files = sorted(file_sizes, key=lambda x: x[1], reverse=True)[:num_files]

        return sorted_files

    except FileNotFoundError:
        print(f"Error: No such file or directory: '{path}'")
        return []

if __name__ == "__main__":
    path = input("Enter the path to analyze (default is current directory): ").strip()

    total, used, free = get_disk_space(path)

    print(f"\nDisk Space Information:")
    print(f"Total Space: {total:.2f} GB")
    print(f"Used Space: {used:.2f} GB")
    print(f"Free Space: {free:.2f} GB")

    largest_files = get_largest_files(path)
    print("\nTop 5 Largest Files:")
    for file, size in largest_files:
        print(f"{file}: {size / (2 ** 20):.2f} MB")
