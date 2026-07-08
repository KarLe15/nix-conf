# quickshell

Configures [Quickshell](https://quickshell.org) — a QtQuick/QML Wayland desktop
shell — as a Home Manager module. This is the Nix side of the "Quickshell Desktop
Shell" design: each design surface (bar, notch launcher, notifications, dock,
widgets) is being ported to QML step by step.

## Status

**Stage 1 — scaffold (current).** Installs Quickshell and ships a minimal `shell.qml`:
a floating top bar on every monitor with a centered clock pill. Its only purpose is
to prove the wiring end to end — package builds, config loads, and theme/font tokens
flow in from the repo's presets.

Quickshell **coexists** with Waybar for now: it is installed but **not autostarted**,
so nothing changes on your desktop until you launch it yourself. Later stages replace
Waybar/Swaync/Rofi surface by surface, and only then does autostart get wired in.

## What it does

- Installs the Quickshell binary from the upstream flake input (`quickshell-pkg`,
  passed in via `home-manager.extraSpecialArgs` in `flake.nix`).
- Generates `~/.config/quickshell/Theme.qml` — a `Singleton` holding the Catppuccin
  palette (matched to the active theme flavor), font families, and shared metrics.
- Writes `~/.config/quickshell/shell.qml` — the shell entry point.

## customConfigs dependencies

| Preset | Field accessed | Used for |
|---|---|---|
| `styleConfigs.themes` | `.apply { inherit pkgs; } → .flavor` | Selects the Catppuccin palette |
| `styleConfigs.fonts`  | `.apply { inherit pkgs; } → .sansSerif.exact-name`, `.mono.exact-name` | UI + mono font families in `Theme.qml` |
| `softwareConfigs.modules.quickshell.enable` | — | Gates the whole module |

## Files

| File | Role |
|---|---|
| `default.nix` | Thin wrapper — imports `home.nix` |
| `home.nix` | Installs the package, generates `Theme.qml`, writes `shell.qml` |
| `qml/shell.qml` | Shell entry point (static source, editable) |

Colors are hardcoded per flavor in `home.nix` (mirroring the approach in
`configurations/style/status-bars/assets/style.css`) so Quickshell and Waybar render
identical hues. Adding a new theme flavor means adding its palette to the `palettes`
attrset in `home.nix`.

## Trying it

After a rebuild, launch manually (it will not fight Waybar):

```sh
qs        # or: quickshell
```

You should see a small clock pill centered in a transparent top bar on each screen.
Edits to `qml/shell.qml` take effect on the next rebuild; Quickshell hot-reloads the
config on file change while running.

## Notes

- No systemd service / Hyprland `exec-once` yet — that arrives with the migration
  stage, once the bar replaces Waybar.
- `Theme.qml` is generated; edit `home.nix`, not the file in `~/.config`.
- For QML language-server support you can drop an empty `.qmlls.ini` next to
  `shell.qml`; Quickshell manages it. Not wired here to keep the config dir clean.
