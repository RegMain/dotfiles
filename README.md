# Desktop configuration

Configuration for this Arch Linux / Hyprland setup. Inspect and back up any
existing configuration before creating symlinks. The files currently assume
the repository is at `/home/alcp/dotfiles`; on another account, review absolute
paths in the systemd units, Qt settings and Hyprland configuration first.

## Main dependencies

The desktop configuration uses Hyprland, `quickshell`, `hyprlock`, `hypridle`,
`hyprpolkitagent`, `rofi`, `wlogout`, `cliphist`, `wl-clipboard`,
`imagemagick`, `file`, `qt5ct`, `qt6ct`, `papirus-icon-theme`,
`ttf-jetbrains-mono-nerd`, `networkmanager`, PipeWire, WirePlumber, BlueZ,
`blueman`, `power-profiles-daemon`, `upower`, `swaybg` and `kconfig`.
The terminal setup also uses Zsh, Oh My Zsh, Starship, `fzf`, `eza`, `bat`,
`zsh-autosuggestions`, `zsh-syntax-highlighting`, and the plugins named in
`.zshrc`. Review existing system setup before installing packages.

## Linking files

These are GNU Stow packages. First inspect the proposed links without making
changes:

```sh
cd ~/dotfiles
stow --no --verbose --target="$HOME" gtk hypr hyprpolkitagent qt5ct qt6ct quickshell rofi systemd
```

Resolve any conflicts manually; do not use `--adopt` to overwrite existing
configuration. When satisfied, run the same command without `--no`. A few
existing configurations, such as `~/.config/hypr/` and `~/.config/rofi/`, may
already contain individual links; check them rather than replacing the whole
directory. `.zshrc` and `starship.toml` are at the repository root and need
their own links, if desired.

After linking, reload user unit definitions with `systemctl --user daemon-reload`.
Hyprland starts the bar and notification services on the next session start.
Qt applications are configured through `QT_QPA_PLATFORMTHEME` in
`hyprland.lua`; a new desktop session is needed for reliable propagation.

## Restore desktop preferences

With Okular closed, run:

```sh
sh ~/dotfiles/setup-desktop-settings.sh
```

This sets three desktop appearance preferences and updates **only**
`UiSettings/ColorScheme` in the existing Okular configuration. It does not
copy, erase, or replace recent-document history. It requires the MinimalDark
color scheme link from the `qt6ct` Stow package and `kwriteconfig6`.
Review and adjust the commands first if you prefer different global settings.

## Fallbacks

Waybar and Mako configuration remains available. To return in the current
session:

```sh
systemctl --user stop quickshell-bar.service quickshell-notifications.service
waybar &
systemctl --user start mako.service
```

To make the fallback persistent, replace the two Quickshell service launches
in `hypr/.config/hypr/hyprland.lua` with the previous Waybar and Mako launches.
