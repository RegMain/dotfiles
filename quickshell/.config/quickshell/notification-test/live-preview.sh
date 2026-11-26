#!/usr/bin/env bash
set -euo pipefail

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
shell_pid=
handover_started=false

# Query the bus itself; querying org.freedesktop.Notifications directly can
# auto-activate Mako before Quickshell has a chance to take ownership.
notification_pid() {
    local reply owner
    reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetNameOwner s org.freedesktop.Notifications 2>/dev/null) || return 1
    read -r _ owner <<< "$reply"
    owner=${owner//\"/}
    reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetConnectionUnixProcessID s "$owner") || return 1
    read -r _ pid <<< "$reply"
    printf '%s\n' "$pid"
}

restore() {
    local owner
    trap - EXIT INT TERM
    if [[ -n $shell_pid ]]; then
        kill -TERM "$shell_pid" 2>/dev/null || true
        wait "$shell_pid" 2>/dev/null || true
    fi
    if [[ $handover_started == true ]]; then
        if ! systemctl --user start mako.service; then
            echo "ERROR: could not restart Mako. Run: systemctl --user start mako.service" >&2
            return 1
        fi
        for ((i = 0; i < 50; i++)); do
            owner=$(notification_pid) || owner=
            if [[ -n $owner && $(ps -p "$owner" -o comm= 2>/dev/null) == mako ]]; then
                echo "Mako is restored."
                return 0
            fi
            sleep 0.1
        done
        echo "ERROR: Mako ownership not confirmed. Run: systemctl --user status mako.service" >&2
        return 1
    fi
}

if [[ ! -t 0 ]]; then
    echo "Run this script in an interactive terminal." >&2
    exit 1
fi
if qs list --all | grep -Fq "$config_dir/shell.qml"; then
    echo "Close the already running notification-test Quickshell before this test." >&2
    exit 1
fi
mako_pid=$(notification_pid) || {
    echo "Mako must own the notification service before the test." >&2
    exit 1
}
if [[ $(ps -p "$mako_pid" -o comm=) != mako ]]; then
    echo "Another notification server is active; leaving it untouched." >&2
    exit 1
fi

trap restore EXIT
trap 'exit 130' INT TERM
handover_started=true
kill -TERM "$mako_pid"
qs -p "$config_dir" &
shell_pid=$!

owner=
for ((i = 0; i < 100; i++)); do
    if ! kill -0 "$shell_pid" 2>/dev/null; then break; fi
    owner=$(notification_pid) || owner=
    if [[ $owner == "$shell_pid" ]]; then break; fi
    sleep 0.1
done
if [[ $owner != "$shell_pid" ]]; then
    echo "Quickshell did not acquire notifications. Restoring Mako." >&2
    exit 1
fi

echo "Quickshell owns real notifications for up to 60 seconds at a time."
if ! read -r -t 60 -p "Look at the screen, then press Enter to send the test... "; then
    echo "Timed out before sending."
    exit 0
fi

notify-send --urgency=normal --expire-time=0 -a Quickshell-live-test \
    -n /usr/share/pixmaps/htop.png \
    -h string:image-path:/usr/share/pixmaps/archlinux-logo.png \
    "Look here: live notification" "This came through your normal desktop session."
echo "Test sent. You may also wait for real application notifications."
read -r -t 60 -p "Press Enter to restore Mako (automatic in 60 seconds)... " || true
