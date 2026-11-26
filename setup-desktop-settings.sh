#!/bin/sh
# Restore only the desktop settings that are not represented by symlinked files.
set -eu

for command_name in gsettings kwriteconfig6; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    fi
done

if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x okular >/dev/null; then
    printf 'Close Okular before updating its color scheme.\n' >&2
    exit 1
fi

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
scheme_file=${XDG_DATA_HOME:-"$HOME/.local/share"}/color-schemes/MinimalDark.colors
if [ ! -r "$scheme_file" ]; then
    printf 'Install the MinimalDark.colors symlink first: %s\n' "$scheme_file" >&2
    exit 1
fi

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
kwriteconfig6 --file "$config_home/okularrc" --group UiSettings \
    --key ColorScheme MinimalDark
printf 'Desktop preference and Okular color scheme restored.\n'
