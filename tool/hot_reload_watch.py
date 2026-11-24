#!/usr/bin/env python3
"""يراقب مجلد lib/ ويبعت SIGUSR1 لعملية `flutter run` عند أي حفظ.

Flutter بيدعم الإشارتين دول:
  SIGUSR1 -> hot reload
  SIGUSR2 -> hot restart

بلا أي مكتبات إضافية: بنعمل snapshot لأوقات تعديل الملفات كل فترة قصيرة
(60 ملف تقريبًا = تكلفة صفر على المعالج).
"""

import os
import signal
import sys
import time

DEBOUNCE_SECONDS = 0.35
POLL_SECONDS = 0.25
EXTENSIONS = (".dart",)


def watch_root() -> str:
    return os.path.normpath(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib")
    )


def snapshot(root: str) -> dict:
    files = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in {".dart_tool", "build"}]
        for name in filenames:
            if not name.endswith(EXTENSIONS):
                continue
            path = os.path.join(dirpath, name)
            try:
                files[path] = os.stat(path).st_mtime_ns
            except OSError:
                pass
    return files


def read_pid(pid_file: str) -> int | None:
    try:
        with open(pid_file, "r", encoding="utf-8") as handle:
            return int(handle.read().strip())
    except (OSError, ValueError):
        return None


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: hot_reload_watch.py <flutter-pid-file>", file=sys.stderr)
        return 2

    pid_file = sys.argv[1]
    root = watch_root()
    if not os.path.isdir(root):
        print(f"watch: {root} not found", file=sys.stderr)
        return 1

    pid = None
    while pid is None:
        pid = read_pid(pid_file)
        if pid is None:
            time.sleep(POLL_SECONDS)

    print(f"watch: watching {root} -> pid {pid} (Ctrl+C in flutter to quit)")

    state = snapshot(root)
    while True:
        time.sleep(POLL_SECONDS)
        current = snapshot(root)
        if current == state:
            continue

        # تجميع كل التعديلات المتتابعة (حفظ الملفات مرة واحدة) في reload واحد.
        time.sleep(DEBOUNCE_SECONDS)
        current = snapshot(root)
        changed = [p for p, mtime in current.items() if state.get(p) != mtime]
        state = current

        if not changed:
            continue

        try:
            os.kill(pid, signal.SIGUSR1)
        except ProcessLookupError:
            print("watch: flutter run is gone, exiting")
            return 0
        except PermissionError:
            print("watch: no permission to signal flutter run", file=sys.stderr)
            return 1

        names = ", ".join(os.path.relpath(p, root) for p in changed[:3])
        extra = "" if len(changed) <= 3 else f" (+{len(changed) - 3})"
        print(f"watch: ⟳ hot reload [{names}{extra}]")


if __name__ == "__main__":
    sys.exit(main())
