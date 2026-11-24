#!/usr/bin/env bash
# معاينة الموبايل على Linux مع hot reload تلقائي عند أي حفظ.
#
#   tool/dev_preview.sh
#
# مفيش Gradle ومفيش محاكي: النافذة بتفتح بمقاس شاشة هاتف (390×844، مقاس ثابت)
# وأي تعديل في lib/ بيظهر في أقل من ثانية.
#
# تقدر تمرر أي أعلام لـ flutter run، مثال: tool/dev_preview.sh --verbose
set -euo pipefail

cd "$(dirname "$0")/.."

PID_FILE="${PID_FILE:-/tmp/al_ribat_preview.pid}"

# Xwayland: نافذة X11 عادية أسهل في القياس والتصوير من سطح Wayland.
export GDK_BACKEND="${GDK_BACKEND:-x11}"

rm -f "$PID_FILE"

# المراقب ينتظر ظهور ملف الـ PID ثم يبعت SIGUSR1 مع كل حفظ.
python3 -u tool/hot_reload_watch.py "$PID_FILE" &
WATCHER_PID=$!
trap 'kill "$WATCHER_PID" 2>/dev/null || true' EXIT INT TERM

# flutter run في المقدمة عشان r / R / q تفضل شغالة عادي.
flutter run -d linux --pid-file="$PID_FILE" "$@"
