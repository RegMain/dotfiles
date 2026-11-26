# Isolated notification preview

Run this command from your normal terminal:

```sh
bash ~/dotfiles/quickshell/.config/quickshell/notification-test/preview.sh
```

The script starts its own D-Bus session, waits until **Quickshell** owns the
notification service, then sends one test notification. The preview exits
automatically after a few seconds. The test includes an application icon and
a separate image from `/usr/share/pixmaps`. If Quickshell does not take ownership,
the script sends **nothing**; this avoids accidentally activating Mako.

The normal session now starts `quickshell-notifications.service` from
Hyprland's autostart. The isolated preview does not affect that service.
The bar is started separately as `quickshell-bar.service`; both service files
are kept in `~/dotfiles/systemd/.config/systemd/user/`.

## Return to Mako

To switch the current session back to Mako:

```sh
systemctl --user stop quickshell-notifications.service
systemctl --user start mako.service
```

To make that choice persist, also replace the Quickshell notification service
autostart line with `hl.exec_cmd("mako")` in `hyprland.lua`.
