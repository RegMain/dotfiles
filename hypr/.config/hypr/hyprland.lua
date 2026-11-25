-- ~/.config/hypr/hyprland.lua

----------------------------------
---- ПЕРЕМЕННЫЕ (VARIABLES) ------
----------------------------------
local mod = "SUPER"
local left = "code:43"
local down = "code:44"
local up = "code:45"
local right = "code:46"
local term = "alacritty"
local menu = "rofi -show drun"
local filemgr = "thunar"

----------------------------------
---- НАСТРОЙКА МОНИТОРОВ ---------
----------------------------------
hl.monitor({
    output = "eDP-1",
    mode = "2560x1600@60",
    position = "auto",
    scale = 1.6,
})

----------------------------------
---- ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ --------
----------------------------------
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")

debug.disable_logs = false

----------------------------------
---- ОСНОВНЫЕ НАСТРОЙКИ ----------
----------------------------------
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 3,
    },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
            disable_while_typing = true,
            middle_button_emulation = true,
        },
    },
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },
})

----------------------------------
---- АВТОЗАПУСК (AUTOSTART) ------
----------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("xrdb -merge ~/.Xresources")
    hl.exec_cmd("wlsunset -l 55.7 -long 37.6")
    hl.exec_cmd("mako")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("batsignal -w 20 -c 10 -d 5")
    -- hl.exec_dmd("udiskie")
    hl.exec_cmd("v2rayn")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    -- Обои и панель
    hl.exec_cmd("swaybg -i ~/wallpaper.jpg -m fill")
    hl.exec_cmd("waybar")
    
    -- Обновления
    hl.exec_cmd("arch-update --tray")
end)

----------------------------------
---- ПРАВИЛА ОКН (WINDOW RULES) --
----------------------------------
hl.window_rule({
    match = { class = "blueman-manager" },
    float = true,
    size = { 800, 700 },
    center = true,
})

hl.window_rule({
    match = { class = "nmtui_floating" },
    float = true,
    size = { 700, 500 },
    center = true,
})

hl.window_rule({
    match = { class = "v2rayN" },
    float = true,
    center = true,
    size = { 1024, 768 },
    --suppress_event = "maximize"
})

hl.window_rule({
    match = { title = "(?i)(open|save|file|dialog|prefernces|settings|properties)" },
    center = true,
    float = true,
    min_size = { 300, 200 },
    max_size = { 1400, 900 },
    suppress_event = "maximize"
})

----------------------------------
---- ГОРЯЧИЕ КЛАВИШИ (BINDS) -----
----------------------------------

-- Запуск приложений и системные действия
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(term))
hl.bind(mod .. " + code:26", hl.dsp.exec_cmd(filemgr))
hl.bind(mod .. " + code:24", hl.dsp.window.close())
hl.bind(mod .. " + code:39", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + CTRL + code:26", hl.dsp.exec_cmd("swaynag -t warning -m 'Exit Hyprland?' -B 'Yes' 'hyprctl dispatch exit'"))
hl.bind(mod .. " + code:54", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("wlogout"))
hl.bind(mod .. " + SHIFT + code:46", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
-- Навигация фокуса и перемещение окон
local dirs = {
    [left] = "l", ["Left"] = "l",
    [down] = "d", ["Down"] = "d",
    [up] = "u", ["Up"] = "u",
    [right] = "r", ["Right"] = "r"
}

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { moutse = true })

hl.bind(mod .. " + SHIFT + " .. left, hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + " .. down, hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + " .. up, hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + " .. right, hl.dsp.window.move({ direction = "r" }))

hl.bind(mod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))

for key, dir in pairs(dirs) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- Быстрое изменение размера из основного режима
hl.bind(mod .. " + CTRL + " .. left, hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mod .. " + CTRL + " .. down, hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
hl.bind(mod .. " + CTRL + " .. up, hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(mod .. " + CTRL + " .. right, hl.dsp.window.resize({ x = 20, y = 0, relative = true }))

-- Рабочие области (1..10)
for i = 1, 9 do
    hl.bind(mod .. " + " .. tostring(i), hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Макет и сплиты
hl.bind(mod .. " + code:55", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg togglesplit"))
hl.bind(mod .. " + code:41", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))hl.bind(mod .. " + V", hl.dsp.layout(""))
-- Скратчпад
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:scratchpad" }))
hl.bind(mod .. " + minus", hl.dsp.focus({ workspace = "special:scratchpad" }))

----------------------------------
---- РЕЖИМЫ (SUBMAPS) ------------
----------------------------------

-- Режим "R" (Resize)
hl.bind(mod .. " + code:27", hl.dsp.submap("R"))
hl.define_submap("R", function()
    hl.bind(left, hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind(down, hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind(up, hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind(right, hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })

    hl.bind("Left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("Down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("Up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("Right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })

    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind("code:27", hl.dsp.submap("reset"))
    hl.bind(mod .. " + code:27", hl.dsp.submap("reset"))
    hl.bind("Alt_L", hl.dsp.submap("N"))
    hl.bind("SUPER+Alt_L", hl.dsp.submap("N"))
end)

-- Режим "N" (Navigation)
hl.bind("SUPER+Alt_L", hl.dsp.submap("N"))
hl.define_submap("N", function()
    hl.bind(left, hl.dsp.focus({ direction = "l" }))
    hl.bind(down, hl.dsp.focus({ direction = "d" }))
    hl.bind(up, hl.dsp.focus({ direction = "u" }))
    hl.bind(right, hl.dsp.focus({ direction = "r" }))

    hl.bind("Left", hl.dsp.focus({ direction = "l" }))
    hl.bind("Down", hl.dsp.focus({ direction = "d" }))
    hl.bind("Up", hl.dsp.focus({ direction = "u" }))
    hl.bind("Right", hl.dsp.focus({ direction = "r" }))

    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind("SUPER+Alt_L", hl.dsp.submap("reset"))
    hl.bind("Alt_L", hl.dsp.submap("reset"))
    hl.bind("code:27", hl.dsp.submap("R"))

    hl.bind("SHIFT + " .. left, hl.dsp.window.move({ direction = "l" }))
    hl.bind("SHIFT + " .. down, hl.dsp.window.move({ direction = "d" }))
    hl.bind("SHIFT + " .. up, hl.dsp.window.move({ direction = "u" }))
    hl.bind("SHIFT + " .. right, hl.dsp.window.move({ direction = "r" }))

    hl.bind("SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
    hl.bind("SHIFT + Down", hl.dsp.window.move({ direction = "d" }))
    hl.bind("SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
    hl.bind("SHIFT + Right", hl.dsp.window.move({ direction = "r" }))

    for i = 1, 9 do
        hl.bind(tostring(i), hl.dsp.focus({ workspace = i }))
        hl.bind("SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = i }))
    end
    hl.bind("0", hl.dsp.focus({ workspace = 10 }))
    hl.bind("SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
end)

----------------------------------
---- МЕДИА И МУЛЬТИМЕДИА ---------
----------------------------------
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })

hl.bind("XF86SelectiveScreenshot", hl.dsp.exec_cmd("grimshot --notify save area - | tee ~/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy"))
