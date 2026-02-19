#!/usr/bin/env python3
"""
ULTRA-FAST directory size calculator - Windows native API + threading
Usage: pya [path1] [path2] ...
"""

import os
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Tuple, List

# Windows-specific turbo mode
if sys.platform == "win32":
    import ctypes
    from ctypes import wintypes
    
    kernel32 = ctypes.windll.kernel32
    
    INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value
    FILE_ATTRIBUTE_DIRECTORY = 0x10
    FILE_ATTRIBUTE_REPARSE_POINT = 0x400
    
    class WIN32_FIND_DATAW(ctypes.Structure):
        _fields_ = [
            ("dwFileAttributes", wintypes.DWORD),
            ("ftCreationTime", wintypes.FILETIME),
            ("ftLastAccessTime", wintypes.FILETIME),
            ("ftLastWriteTime", wintypes.FILETIME),
            ("nFileSizeHigh", wintypes.DWORD),
            ("nFileSizeLow", wintypes.DWORD),
            ("dwReserved0", wintypes.DWORD),
            ("dwReserved1", wintypes.DWORD),
            ("cFileName", wintypes.WCHAR * 260),
            ("cAlternateFileName", wintypes.WCHAR * 14),
        ]
    
    FindFirstFileW = kernel32.FindFirstFileW
    FindFirstFileW.argtypes = [wintypes.LPCWSTR, ctypes.POINTER(WIN32_FIND_DATAW)]
    FindFirstFileW.restype = wintypes.HANDLE
    
    FindNextFileW = kernel32.FindNextFileW
    FindNextFileW.argtypes = [wintypes.HANDLE, ctypes.POINTER(WIN32_FIND_DATAW)]
    FindNextFileW.restype = wintypes.BOOL
    
    FindClose = kernel32.FindClose
    FindClose.argtypes = [wintypes.HANDLE]
    FindClose.restype = wintypes.BOOL
    
    def get_dir_size_fast(path: str) -> int:
        """Ultra-fast iterative size calc using Windows native API."""
        total = 0
        stack = [path]
        find_data = WIN32_FIND_DATAW()
        
        while stack:
            current = stack.pop()
            search_path = os.path.join(current, "*")
            
            handle = FindFirstFileW(search_path, ctypes.byref(find_data))
            if handle == INVALID_HANDLE_VALUE:
                continue
            
            try:
                while True:
                    name = find_data.cFileName
                    if name not in (".", ".."):
                        attrs = find_data.dwFileAttributes
                        if not (attrs & FILE_ATTRIBUTE_REPARSE_POINT):
                            if attrs & FILE_ATTRIBUTE_DIRECTORY:
                                stack.append(os.path.join(current, name))
                            else:
                                total += (find_data.nFileSizeHigh << 32) + find_data.nFileSizeLow
                    
                    if not FindNextFileW(handle, ctypes.byref(find_data)):
                        break
            finally:
                FindClose(handle)
        
        return total

else:
    # Linux/Mac: optimized os.scandir
    def get_dir_size_fast(path: str) -> int:
        """Ultra-fast iterative size calc using os.scandir."""
        total = 0
        stack = [path]
        
        while stack:
            current = stack.pop()
            try:
                with os.scandir(current) as it:
                    for entry in it:
                        try:
                            if entry.is_symlink():
                                continue
                            if entry.is_file(follow_symlinks=False):
                                total += entry.stat(follow_symlinks=False).st_size
                            elif entry.is_dir(follow_symlinks=False):
                                stack.append(entry.path)
                        except (PermissionError, OSError):
                            pass
            except (PermissionError, OSError):
                pass
        
        return total


def format_size(size_bytes: int) -> str:
    """Format bytes as MB."""
    return f"{size_bytes / (1024 * 1024):>12,.2f} MB"


def calc_subdir_size(args: Tuple[str, str]) -> Tuple[str, int]:
    """Worker function for threading."""
    name, path = args
    try:
        return (name, get_dir_size_fast(path))
    except Exception:
        return (name, 0)


def get_folder_sizes(path: str) -> Tuple[List[Tuple[str, int]], int]:
    """Get sizes of all immediate subfolders and root files."""
    folders = []
    root_files_size = 0
    subdirs = []
    
    try:
        with os.scandir(path) as it:
            for entry in it:
                try:
                    if entry.is_symlink():
                        continue
                    if entry.is_file(follow_symlinks=False):
                        root_files_size += entry.stat(follow_symlinks=False).st_size
                    elif entry.is_dir(follow_symlinks=False):
                        subdirs.append((entry.name, entry.path))
                except (PermissionError, OSError):
                    pass
    except (PermissionError, OSError) as e:
        print(f"Error: {path}: {e}", file=sys.stderr)
        return [], 0
    
    # Parallel calculation using ThreadPoolExecutor (no spawn issues on Windows!)
    if subdirs:
        workers = min(32, len(subdirs))
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {executor.submit(calc_subdir_size, s): s[0] for s in subdirs}
            for future in as_completed(futures):
                try:
                    result = future.result()
                    folders.append(result)
                except Exception:
                    pass
    
    folders.sort(key=lambda x: x[1], reverse=True)
    return folders, root_files_size


def pya(path: str) -> int:
    """Show sizes of all folders in directory. Returns total."""
    path = os.path.abspath(path)
    print(f"\n═══ {path} ═══")
    
    folders, root_files_size = get_folder_sizes(path)
    
    if not folders and root_files_size == 0:
        print("0.00 MB")
        return 0
    
    total = root_files_size
    max_name_len = max((len(f[0]) for f in folders), default=7)
    max_name_len = max(max_name_len, 7)
    
    for name, size in folders:
        total += size
        if size > 0:
            print(f"{name:<{max_name_len}}  {format_size(size)}")
    
    if root_files_size > 0:
        print(f"{'<files>':<{max_name_len}}  {format_size(root_files_size)}")
    
    print("─" * (max_name_len + 16))
    print(f"{'Total':<{max_name_len}}  {format_size(total)}")
    return total


def main():
    paths = sys.argv[1:] if len(sys.argv) > 1 else ["."]
    
    path_totals = []
    grand_total = 0
    
    for path in paths:
        if not os.path.exists(path):
            print(f"\n═══ {path} ═══\nError: Path does not exist")
            continue
        total = pya(path)
        path_totals.append((path, total))
        grand_total += total
    
    if len(paths) > 1:
        print(f"\n{'═' * 50}\nGRAND TOTAL\n{'─' * 50}")
        ml = max(len(p) for p, _ in path_totals)
        for p, t in path_totals:
            print(f"{p:<{ml}}  {format_size(t)}")
        print("─" * 50)
        print(f"{'All':<{ml}}  {format_size(grand_total)}")


if __name__ == "__main__":
    main()
