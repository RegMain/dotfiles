#!/usr/bin/env bash
set -euo pipefail

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ ${QUICKSHELL_NOTIFICATION_PREVIEW:-} != isolated ]]; then
    exec dbus-run-session -- env QUICKSHELL_NOTIFICATION_PREVIEW=isolated \
        bash "$config_dir/preview.sh"
fi

qs -p "$config_dir" &
shell_pid=$!
trap 'kill "$shell_pid" 2>/dev/null || true; wait "$shell_pid" 2>/dev/null || true' EXIT

owner_pid=
for ((attempt = 0; attempt < 100; attempt++)); do
    if ! kill -0 "$shell_pid" 2>/dev/null; then
        echo "Quickshell exited before registering notifications." >&2
        exit 1
    fi

    if reply=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus GetNameOwner s org.freedesktop.Notifications 2>/dev/null); then
        read -r _ owner <<< "$reply"
        owner=${owner//\"/}
        read -r _ owner_pid <<< "$(busctl --user call org.freedesktop.DBus \
            /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID \
            s "$owner")"
        break
    fi
    sleep 0.1
done

if [[ $owner_pid != "$shell_pid" ]]; then
    echo "Quickshell did not acquire notifications; no test was sent." >&2
    exit 1
fi

echo "Quickshell owns the isolated notification service (PID $shell_pid)."
notify-send --expire-time=5000 -a Quickshell-test \
    -n /usr/share/pixmaps/htop.png \
    -h string:image-path:/usr/share/pixmaps/archlinux-logo.png \
    "Image preview" "This image and app icon should appear in Quickshell, not Mako."
sleep 7
