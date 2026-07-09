# quickshell

Configures [Quickshell](https://quickshell.org) — a QtQuick/QML Wayland desktop
shell — as a Home Manager module. This is the Nix side of the "Quickshell Desktop
Shell" design: each design surface (bar, notch launcher, notifications, dock,
widgets) is being ported to QML step by step.

## Status

**Stage 2 — status bar (current).** Ships the "Screen Bars · Filled" direction: a
solid Crust top bar on every monitor with three zones —

- **left**: a clock island (glyph · `HH:mm` · date) — the ultrawide (hub) shows the
  full time + date, the side screens show time only; clicking it drops a month
  calendar popover (Calendar Widget · 7b),
- **center**: the full 1–9 workspace strip (id · `:` · Nerd Font glyph), with live
  occupancy from Hyprland and click-to-switch — the **focused** workspace (where
  input focus is) is highlighted, consistently across every bar,
- **right**: a basic system module (CPU · temp, and volume).

Colored, filled, dark-on-accent pills, matched to the machine's Catppuccin flavor.
Workspace ids/glyphs come from the repo's own `workspaces` + `monitors` presets (the
monitor binding is code → 1/4/7, terminal → 2/5/8, browser → 3/6/9, which drives the
per-monitor active highlight).

Quickshell still **coexists** with Waybar: it is installed but **not autostarted**,
so nothing changes on your desktop until you launch it yourself (`qs`). The adaptive
system module + hover panel (Stage 3), notifications (Stage 4), and the notch
launcher / stargate dock (Stage 5) are not implemented yet.

## What it does

- Installs the Quickshell binary from the upstream flake input (`quickshell-pkg`,
  passed in via `home-manager.extraSpecialArgs` in `flake.nix`).
- Generates `~/.config/quickshell/Theme.qml` — a `Singleton` holding the Catppuccin
  palette (matched to the active theme flavor), semantic color aliases, font
  families, and shared metrics.
- Generates `~/.config/quickshell/Config.qml` — a `Singleton` holding the
  per-monitor workspace layout (`{ id, icon, monitor }`) projected from the
  `workspaces`/`monitors` presets, plus the `hubMonitor` (ultrawide) name.
- Writes the static QML component tree (`shell.qml`, `Bar.qml`, `widgets/*.qml`).

## customConfigs dependencies

| Preset | Field accessed | Used for |
|---|---|---|
| `styleConfigs.themes` | `.apply { pkgs } → .flavor` | Selects the Catppuccin palette |
| `styleConfigs.fonts`  | `.apply { pkgs } → .sansSerif.exact-name`, `.mono.exact-name` | UI + mono font families in `Theme.qml` |
| `hardwareConfigs.monitors` | `.apply { pkgs } → .disposition` | Hub monitor + monitor names |
| `styleConfigs.workspaces` | `.apply { pkgs, monitors } → .workspaces_defined` | Per-monitor workspace ids/glyphs in `Config.qml` |
| `softwareConfigs.modules.quickshell.enable` | — | Gates the whole module |

## Files

| File | Role |
|---|---|
| `default.nix` | Thin wrapper — imports `home.nix` |
| `home.nix` | Installs the package, generates `Theme.qml` + `Config.qml`, writes the QML tree |
| `qml/shell.qml` | Entry point — one `Bar` per screen via `Variants` |
| `qml/Bar.qml` | Per-monitor `PanelWindow` (solid bar, three zones) |
| `qml/widgets/Clock.qml` | Left clock island + calendar trigger (`compact` = time only) |
| `qml/widgets/CalendarPopup.qml` | `PopupWindow` anchored under the clock |
| `qml/widgets/CalendarView.qml` | Month calendar body (Monday-first, today/weekend/other-month states) |
| `qml/widgets/Workspaces.qml` | Center workspace pills (Hyprland-driven) |
| `qml/widgets/SystemModule.qml` | Right system pills (CPU/temp + volume) |

Colors are hardcoded per flavor in `home.nix` (mirroring the approach in
`configurations/style/status-bars/assets/style.css`) so Quickshell and Waybar render
identical hues. Adding a new theme flavor means adding its palette to the `palettes`
attrset in `home.nix`. The accent is **mauve** (Screen Bars 1a); change the
`accent:` alias in the generated `Theme.qml` block in `home.nix` to switch it.

## Singletons

`Theme.qml` and `Config.qml` are generated with a real `pragma Singleton` (not the
`//@ pragma` comment) and imported via `import "root:/"`. Components then read
`Theme.<prop>` / `Config.<prop>` directly. This was validated headlessly with
`QT_QPA_PLATFORM=offscreen qs -p …` — with the comment form the singletons resolve
as bare types and every property reads `undefined`.

## Trying it

After a rebuild, launch manually (it will not fight Waybar):

```sh
qs        # or: quickshell
```

You should see a solid top bar on each screen: clock left, that monitor's workspace
pills center, CPU/temp + volume right. Click a workspace pill to switch to it.
Quickshell hot-reloads on file change; edits to the QML take effect on the next
rebuild.

## Notes

- No systemd service / Hyprland `exec-once` yet — that arrives with the migration
  stage, once the bar replaces Waybar.
- `Theme.qml` and `Config.qml` are generated; edit `home.nix`, not the files in
  `~/.config`.
- The system module polls `/proc/stat` + a thermal zone and `wpctl` every 2s. If
  volume shows `--`, check `wpctl get-volume @DEFAULT_AUDIO_SINK@`; if temp looks
  wrong, adjust the `thermal_zone0` path in `widgets/SystemModule.qml`.
