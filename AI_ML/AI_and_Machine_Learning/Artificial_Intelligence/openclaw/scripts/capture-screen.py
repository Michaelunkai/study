from __future__ import annotations

import argparse
import ctypes
import sys
import time
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageGrab

try:
    from pywinauto import Desktop
except Exception as exc:  # pragma: no cover - runtime dependency check
    Desktop = None
    IMPORT_ERROR = exc
else:
    IMPORT_ERROR = None

MAX_CAPTURE_DIMENSION = 2048

if sys.platform == "win32":
    from ctypes import wintypes

    MONITORINFOF_PRIMARY = 1

    class RECT(ctypes.Structure):
        _fields_ = [
            ("left", ctypes.c_long),
            ("top", ctypes.c_long),
            ("right", ctypes.c_long),
            ("bottom", ctypes.c_long),
        ]


    class MONITORINFOEXW(ctypes.Structure):
        _fields_ = [
            ("cbSize", wintypes.DWORD),
            ("rcMonitor", RECT),
            ("rcWork", RECT),
            ("dwFlags", wintypes.DWORD),
            ("szDevice", ctypes.c_wchar * 32),
        ]

for stream_name in ("stdout", "stderr"):
    stream = getattr(sys, stream_name, None)
    try:
        stream.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture the full desktop or a specific visible window."
    )
    parser.add_argument(
        "--out",
        help="Output PNG path. Defaults to a timestamped file next to this script.",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Capture the full virtual desktop across all monitors.",
    )
    parser.add_argument(
        "--monitor",
        type=int,
        help="Capture exactly one monitor by 1-based index.",
    )
    parser.add_argument(
        "--title-contains",
        help="Capture the single visible window whose title contains this text.",
    )
    parser.add_argument(
        "--title-exact",
        help="Capture the single visible window whose title exactly matches this text.",
    )
    parser.add_argument(
        "--list-windows",
        action="store_true",
        help="List visible window titles and exit.",
    )
    parser.add_argument(
        "--list-monitors",
        action="store_true",
        help="List monitor indices and bounds, then exit.",
    )
    return parser.parse_args()


def require_desktop() -> None:
    if Desktop is None:
        raise SystemExit(f"pywinauto import failed: {IMPORT_ERROR}")


def default_output_path() -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return Path(__file__).resolve().parent / f"screen-{stamp}.png"


def iter_visible_windows():
    require_desktop()
    seen = set()
    for window in Desktop(backend="uia").windows():
        try:
            title = (window.window_text() or "").strip()
            rect = window.rectangle()
        except Exception:
            continue
        if not title:
            continue
        if rect.width() <= 0 or rect.height() <= 0:
            continue
        key = (title, rect.left, rect.top, rect.right, rect.bottom)
        if key in seen:
            continue
        seen.add(key)
        yield window, title, rect


def list_monitors() -> int:
    monitors = get_monitors()
    if not monitors:
        raise SystemExit("No monitors detected.")
    for monitor in monitors:
        rect = monitor["rect"]
        print(
            f'{monitor["index"]}: device={monitor["device"]} primary={monitor["primary"]} '
            f'rect=({rect.left},{rect.top},{rect.right},{rect.bottom})'
        )
    return 0


def list_windows() -> int:
    titles = sorted({title for _, title, _ in iter_visible_windows()})
    for title in titles:
        print(title)
    return 0


def find_matching_windows(title_contains: str | None, title_exact: str | None):
    matches = []
    for window, title, rect in iter_visible_windows():
        title_cmp = title.casefold()
        if title_exact and title_cmp != title_exact.casefold():
            continue
        if title_contains and title_contains.casefold() not in title_cmp:
            continue
        matches.append((window, title, rect))
    return matches


def capture_full(output_path: Path) -> None:
    image = ImageGrab.grab(all_screens=True)
    save_image(output_path, image)


def focus_window(window) -> None:
    try:
        window.restore()
    except Exception:
        pass
    try:
        window.set_focus()
    except Exception:
        pass
    time.sleep(0.3)


def capture_window(output_path: Path, rect) -> None:
    bbox = (rect.left, rect.top, rect.right, rect.bottom)
    image = ImageGrab.grab(bbox=bbox, all_screens=True)
    save_image(output_path, image)


def get_monitors():
    if sys.platform != "win32":
        raise SystemExit("Monitor enumeration is only supported on Windows.")

    user32 = ctypes.windll.user32
    monitors = []

    monitor_enum_proc = ctypes.WINFUNCTYPE(
        ctypes.c_int,
        wintypes.HMONITOR,
        wintypes.HDC,
        ctypes.POINTER(RECT),
        wintypes.LPARAM,
    )

    def callback(hmonitor, _hdc, _rect, _lparam):
        info = MONITORINFOEXW()
        info.cbSize = ctypes.sizeof(info)
        if not user32.GetMonitorInfoW(hmonitor, ctypes.byref(info)):
            return 1
        monitors.append(
            {
                "index": len(monitors) + 1,
                "device": info.szDevice,
                "primary": bool(info.dwFlags & MONITORINFOF_PRIMARY),
                "rect": info.rcMonitor,
            }
        )
        return 1

    if not user32.EnumDisplayMonitors(0, 0, monitor_enum_proc(callback), 0):
        raise SystemExit("Failed to enumerate monitors.")
    return monitors


def capture_monitor(output_path: Path, monitor_index: int) -> None:
    monitors = get_monitors()
    match = next((monitor for monitor in monitors if monitor["index"] == monitor_index), None)
    if match is None:
        raise SystemExit(f"Monitor {monitor_index} was not found.")
    rect = match["rect"]
    bbox = (rect.left, rect.top, rect.right, rect.bottom)
    image = ImageGrab.grab(bbox=bbox, all_screens=True)
    save_image(output_path, image)


def normalize_image(image):
    width, height = image.size
    longest_side = max(width, height)
    if longest_side <= MAX_CAPTURE_DIMENSION:
        return image

    scale = MAX_CAPTURE_DIMENSION / float(longest_side)
    resized = image.resize(
        (max(1, int(width * scale)), max(1, int(height * scale))),
        resample=getattr(Image, "Resampling", Image).LANCZOS,
    )
    image.close()
    return resized


def save_image(output_path: Path, image) -> None:
    normalized = normalize_image(image)
    try:
        normalized.save(output_path)
    finally:
        normalized.close()


def main() -> int:
    args = parse_args()

    if args.monitor is not None and args.monitor < 1:
        raise SystemExit("--monitor must be a 1-based positive index.")

    mode_count = sum(
        1
        for enabled in (
            args.full,
            bool(args.monitor),
            bool(args.title_contains),
            bool(args.title_exact),
            args.list_windows,
            args.list_monitors,
        )
        if enabled
    )
    if mode_count == 0:
        args.full = True
    elif (args.list_windows or args.list_monitors) and mode_count > 1:
        raise SystemExit("--list-windows and --list-monitors cannot be combined with capture flags.")
    elif mode_count > 1:
        raise SystemExit("Choose exactly one of --full, --monitor, --title-contains, or --title-exact.")

    if args.list_windows:
        return list_windows()
    if args.list_monitors:
        return list_monitors()

    output_path = Path(args.out).expanduser() if args.out else default_output_path()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        if args.full:
            capture_full(output_path)
            print(output_path)
            return 0

        if args.monitor:
            capture_monitor(output_path, args.monitor)
            print(output_path)
            return 0

        matches = find_matching_windows(args.title_contains, args.title_exact)
        if not matches:
            if args.title_exact:
                raise SystemExit(f'No visible window found with exact title "{args.title_exact}".')
            raise SystemExit(f'No visible window found containing "{args.title_contains}".')
        if len(matches) > 1:
            lines = []
            for _, title, rect in matches:
                lines.append(f'- "{title}" @ ({rect.left},{rect.top},{rect.right},{rect.bottom})')
            raise SystemExit(
                "Multiple visible windows matched. Narrow the title and retry:\n" + "\n".join(lines)
            )

        window, _, _ = matches[0]
        focus_window(window)
        rect = window.rectangle()
        capture_window(output_path, rect)
        print(output_path)
        return 0
    except SystemExit:
        raise
    except Exception as exc:
        raise SystemExit(f"Capture failed: {exc}") from exc


if __name__ == "__main__":
    sys.exit(main())
