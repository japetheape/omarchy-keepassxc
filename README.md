# KeePassXC for Omarchy

An unofficial Omarchy Quattro bar widget for KeePassXC. It shows a reduced application state, launches or focuses KeePassXC, locks open databases, and exposes top-level actions published by KeePassXC's native tray item.

## Requirements

- A current Omarchy Quattro installation
- KeePassXC 2.7 or newer
- `bash`, `gtk-launch`, `hyprctl`, `jq`, `pgrep`, `setsid`, `timeout`, and `uwsm-app`

Omarchy supplies the runtime commands above on a standard installation. KeePassXC is the only additional application dependency.

## Install

```sh
omarchy plugin add https://github.com/japetheape/omarchy-keepassxc.git --enable
```

The widget defaults to the right section of the bar. Move it with Omarchy's bar settings if needed.

## Use

- Left click: open or close the status panel
- Right click: launch or focus KeePassXC
- Open/Launch action: show the running application or start it through `uwsm-app`
- Lock action: ask KeePassXC to lock all open databases
- KeePassXC actions: invoke available top-level actions from its native tray menu

The icon distinguishes stopped, running, locked, and unlocked states when KeePassXC publishes enough metadata. Ambiguous metadata is reported conservatively as running.

## Privacy and security

The plugin does not read password databases, passwords, browser-integration messages, or KeePassXC configuration. It does not access the network, elevate privileges, install packages, or modify user configuration.

KeePassXC and Hyprland publish window and tray titles. The plugin compares those values in memory with KeePassXC's known locked and database-window formats, reduces them to a state, and never displays, logs, or stores the original title or database name.

Native tray actions are supplied and executed by KeePassXC. The plugin only renders and triggers the top-level actions KeePassXC publishes.

## Optional integration

The plugin does not change keybindings, window rules, menus, or KeePassXC settings automatically.

### Keybindings

Add equivalent bindings to `~/.config/hypr/bindings.lua` if desired:

```lua
o.bind("SUPER + SHIFT + SLASH", "Passwords", "bash \"$HOME/.config/omarchy/plugins/io.github.japetheape.keepassxc/launch.sh\"")
o.bind("SUPER + CTRL + L", "Lock system", "bash \"$HOME/.config/omarchy/plugins/io.github.japetheape.keepassxc/lock-session.sh\"")
```

`lock-session.sh` waits for the bounded KeePassXC lock attempt before locking the Omarchy session. It still locks the session if KeePassXC returns an error, then reports that error to its caller.

### Window privacy

The following optional rule keeps KeePassXC floating and excludes it from screen sharing:

```lua
o.window("^org\\.keepassxc\\.KeePassXC$", { no_screen_share = true, tag = "+floating-window" })
```

Add it to `~/.config/hypr/hyprland.lua`, then run `hyprctl reload` and check `hyprctl configerrors`.

### Close to tray

To make closing KeePassXC hide it without ending the current unlocked session, enable these settings in KeePassXC:

```ini
[GUI]
MinimizeOnClose=true
MinimizeToTray=true
ShowTrayIcon=true

[Security]
LockDatabaseMinimize=false
LockDatabaseScreenLock=true
```

Confirm the dedicated widget works before hiding the generic `KeePassXC` entry through Omarchy's tray management popup. Enabling `LockDatabaseScreenLock` ensures KeePassXC also locks when the desktop session locks.

## Development

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.japetheape.keepassxc
node ~/.config/omarchy/plugins/io.github.japetheape.keepassxc/test-model.js
bash ~/.config/omarchy/plugins/io.github.japetheape.keepassxc/tests/test-scripts.sh
qmllint -I /usr/share/omarchy/shell ~/.config/omarchy/plugins/io.github.japetheape.keepassxc/Panel.qml
```

## Remove

```sh
omarchy plugin remove io.github.japetheape.keepassxc
```

Optional keybindings, window rules, menu overrides, tray preferences, and KeePassXC settings are user configuration and must be removed separately.

## License

MIT
