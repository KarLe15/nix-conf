# quickshell

Configures [Quickshell](https://quickshell.org) — a QtQuick/QML Wayland desktop
shell — as a Home Manager module. This is the Nix side of the "Quickshell Desktop
Shell" design: each design surface (bar, notch launcher, notifications, dock,
widgets) is being ported to QML step by step.

## Status

**Stages 1–3 done, plus several Stage 6 widgets.** Ships the "Screen Bars · Filled"
direction: a solid Crust top bar on every monitor, with a **different composition per
screen** driven by that monitor's role (`code` / `terminal` / `browser` / `other`).
The layout is data, not code — it comes from the
`configurations/style/quickshell/` preset (see [Bar layout](#bar-layout)).

| Screen (role) | left | center | right |
|---|---|---|---|
| **browser** (ultrawide hub) | session · clock (time + date) · DND, REC stubs · submap · idle-inhibitor stub | workspaces | system module · GameMode + scheduler stubs · volume/BT · notification stub |
| **code** (primary) | session · avatar · Home + Downloads launch buttons | workspaces | submap · CPU/GPU temps · volume/BT |
| **terminal** | session · clock (compact) · submap | workspaces | LLM stub (dashed) · net up/down |
| **other** (unmapped) | session · clock (compact) | workspaces | system module · volume/BT |

What the real widgets do:

- **clock** — glyph · `HH:mm` · date, in the `Theme.locale` locale (`fr_FR`);
  `compact = true` drops the date. Click drops a month calendar popover
  (Calendar Widget · 7b).
- **workspaces** — the full nine-slot strip (id · `:` · Nerd Font glyph), live
  occupancy from Hyprland and click-to-switch; the **focused** workspace is
  highlighted, consistently across every bar. The slots are **session-relative**:
  in session 7 the same nine pills address workspaces 61–69, keeping their glyphs.
- **submap** — the active Hyprland submap, reading `default` when there is none.
  Submaps are modal (only their own binds fire), so the pill filling with the
  submap's colour is what tells you the keyboard is in a mode. Name, icon and
  colour come from the `submaps` attrset in the shortcuts preset; an undeclared
  submap falls back to its raw name.
- **session** — the active workspace session plus the other open ones (a session is
  open when it holds at least one window). Click a number to switch. See
  [docs/HYPRLAND_SESSIONS.md](../../docs/HYPRLAND_SESSIONS.md).
- **system** — adaptive context pill (precedence gaming → llm → container →
  standard) showing the top context's headline metric; click for a panel of CPU/MEM/
  GPU meters, net, a context hero line (top procs / model cards / container list /
  sparklines), and systemd status.
- **volume** — Pipewire volume/mute + connected BlueZ device; click for a control
  popover (output, volume slider, Bluetooth toggle, device list with connect/
  battery/scan).
- **systemp** — CPU (`k10temp`) + GPU (`amdgpu`) package temperatures.
- **network** — upload + download rate pills.
- **avatar** — profile photo masked into a disc with a lavender ring.
- **action** — icon-only pill that runs a shell command detached (Home / Downloads
  shortcuts, built from the repo's default file explorer).

Anything else in the layout renders as a **`StubPill`**: a design placeholder with no
backend, so unbuilt modules (DND, REC, idle inhibitor, GameMode, scheduler,
notification count, the troll pill) already appear in the right place.

Colored, filled, dark-on-accent pills, matched to the machine's Catppuccin flavor.
Workspace ids/glyphs come from the repo's own `workspaces` + `monitors` presets (the
monitor binding is code → 1/4/7, terminal → 2/5/8, browser → 3/6/9, which drives the
per-monitor active highlight).

Quickshell now runs as a **managed user service** bound to `graphical-session.target`,
and has **replaced Waybar** (`software.modules.waybar.enable = false`).
Notifications (Stage 4) and the notch launcher / stargate dock (Stage 5) are not
implemented yet.

## What it does

- Installs the Quickshell binary from the upstream flake input (`quickshell-pkg`,
  passed in via `home-manager.extraSpecialArgs` in `flake.nix`).
- Generates `~/.config/quickshell/Theme.qml` — a `Singleton` holding the Catppuccin
  palette (matched to the active theme flavor), semantic color aliases, font
  families, the date/time locale, and shared metrics.
- Generates `~/.config/quickshell/Config.qml` — a `Singleton` holding the
  per-monitor workspace layout (`{ id, icon, monitor }`) projected from the
  `workspaces`/`monitors` presets, the connector→role map, the `hubMonitor`
  (ultrawide) name, the session banding, the submap presentation map, the
  per-screen `barLayout`, and the avatar image path.
- Writes the static QML component tree (`shell.qml`, `Bar.qml`, `Sys.qml`,
  `Popovers.qml`, `widgets/*.qml`), the `scripts/` helpers, and the avatar photo.

## Bar layout

Each zone entry is an attrset dispatched by `qml/widgets/WidgetSlot.qml`:

```nix
{ w = "clock"; compact = true; }                                   # a real widget
{ w = "action"; icon = "f015"; color = "blue"; command = "…"; }    # launches a command
{ w = "stub"; icon = "f11c"; label = "resize"; color = "peach"; }  # design placeholder
```

| Key | Meaning |
|---|---|
| `w` | Widget name: `clock`, `workspaces`, `session`, `submap`, `system`, `systemp`, `network`, `volume`, `avatar`, `action` — anything else (notably `stub`) falls back to `StubPill` |
| `icon` | Nerd Font codepoint, hex without the backslash — serialized as `\uXXXX` |
| `label` | Text beside the glyph |
| `color` | `Theme` palette name (`peach`, `sapphire`, …) |
| `command` | Shell command for `w = "action"`, run detached via `Quickshell.execDetached` |
| `compact` | Clock shows time only |
| `dashed` | Stub drawn with a dashed ring (conditional pills) |

The layout normally comes from the active preset
(`configurations/style/quickshell/presets/<style.quickshell.active>.nix`); a host can
override the whole map with `software.modules.quickshell.bars` (empty = use the
preset). **Adding a real widget** = write the component under `qml/widgets/`, add a
case to `WidgetSlot.qml`, then name it in the preset.

## System metrics

`qml/Sys.qml` is a `pragma Singleton`, so it is **process-global**: one poller set
serves all three bars. It is the only component that talks to the system — every
widget is a pure view reading `Sys.<prop>`.

| Poller | Interval | Source | Provides |
|---|---|---|---|
| metrics | 2 s | `/proc/stat`, `/proc/meminfo`, `/proc/net/dev`, `/sys/class/hwmon/*`, `/sys/class/drm/card*/device` | CPU %, CPU/GPU temp, GPU %, GPU watts, RAM, VRAM, net rx/tx |
| context | 5 s | `scripts/context.sh` | context, systemd running/failed, ollama models, docker containers |
| procs | 5 s | `ps` | top-3 CPU processes |

The metrics poller is one shell one-shot echoing every number on a single line, so a
snapshot is internally consistent; `Sys` also keeps a rolling 40-sample history for
the gaming sparklines. The boundary is deliberate — a future socket/DBus daemon could
push into these same properties without touching a widget.

**Audio and Bluetooth bypass `Sys`**: `VolumeBluetooth.qml` binds Quickshell's own
`Quickshell.Services.Pipewire` and `Quickshell.Bluetooth` services (live objects, no
polling).


## Service and restart-on-rebuild

Quickshell runs as `systemd.user.services.quickshell`, `PartOf` and `WantedBy`
`graphical-session.target`, guarded by `ConditionEnvironment=WAYLAND_DISPLAY` —
the same shape Waybar's own unit used.

The part that matters is **`X-Restart-Triggers`**. Quickshell watches the
*resolved* path of its config files, and Home Manager installs those as symlinks
into the Nix store, whose targets are immutable. A rebuild swaps the symlink, the
resolved store path never changes, the file watcher never fires — and the running
shell keeps executing the previous generation until it is restarted by hand. That
bit repeatedly during development.

Listing the generated singletons, the QML tree and the avatar as restart triggers
makes the unit text change whenever any of them does, so Home Manager's `sd-switch`
restarts the service on activation. Reload is not an option: there is no IPC to
re-read the config in place.

```
systemctl --user status quickshell
systemctl --user restart quickshell
journalctl --user -u quickshell -f
```

`qs` is still on `PATH` for running a second instance by hand (useful with
`QT_QPA_PLATFORM=offscreen` for the headless checks described above).
## Popovers

`qml/Popovers.qml` (singleton) coordinates the drop-downs so that only one is open at
a time (each binds `visible: Popovers.active === <self>`), and a `HyprlandFocusGrab`
covering the popover **plus every registered bar** dismisses it on an outside click.
Including the bars in the grab means clicking another chip swaps the popover in one
click instead of the grab eating the first click.

## customConfigs dependencies

| Preset | Field accessed | Used for |
|---|---|---|
| `styleConfigs.themes` | `.apply { pkgs } → .flavor` | Selects the Catppuccin palette |
| `styleConfigs.fonts`  | `.apply { pkgs } → .sansSerif.exact-name`, `.mono.exact-name` | UI + mono font families in `Theme.qml` |
| `hardwareConfigs.monitors` | `.apply { pkgs } → .disposition` | Hub monitor, monitor names, connector→role map |
| `styleConfigs.workspaces` | `.apply { pkgs, monitors } → .workspaces_defined`, `.sessions` | Per-monitor workspace slots/glyphs and the session banding in `Config.qml` |
| `styleConfigs.quickshell` | `.apply { pkgs, default-programs } → .bars`, `.profile-image` | Per-screen bar layout + avatar photo |
| `softwareConfigs.shortcuts` | `.submaps` | Submap presentation (name/icon/colour) for the submap pill |
| `softwareConfigs.defaults` | `.apply { pkgs }` | Passed to the quickshell preset so launch actions use the repo's default programs |
| `softwareConfigs.modules.quickshell.enable` | — | Gates the whole module |
| `softwareConfigs.modules.quickshell.bars` | (attrs) | Overrides the per-screen bar layout; empty = the preset's layout |

## Files

| File | Role |
|---|---|
| `default.nix` | Thin wrapper — imports `home.nix` |
| `home.nix` | Installs the package, generates `Theme.qml` + `Config.qml`, writes the QML tree, scripts and avatar |
| `scripts/context.sh` | Context probe — GameMode (session bus), ollama (`/api/ps`), docker, systemd; emits `key=value` lines |
| `qml/shell.qml` | Entry point — one `Bar` per screen via `Variants` |
| `qml/Bar.qml` | Per-monitor `PanelWindow` — three zones, each a `Repeater` over `Config.barLayout[role]` |
| `qml/Sys.qml` | Singleton — single source of truth for system metrics/context (one poller set, shared by all bars); widgets are pure views over it |
| `qml/Popovers.qml` | Singleton coordinating popover dismissal (one-at-a-time + Hyprland focus-grab click-outside) |
| `qml/widgets/WidgetSlot.qml` | Dispatches one layout entry (`{ w, … }`) to its widget, or a `StubPill` fallback |
| `qml/widgets/StubPill.qml` | Static design stub pill (icon/label/palette-color from layout data) for not-yet-built widgets |
| `qml/widgets/SessionPill.qml` | Workspace-session indicator — active session + the open ones, derived from workspace ids; click to switch |
| `qml/widgets/SubmapPill.qml` | Active-submap indicator — name from the raw Hyprland IPC `submap` event; always visible, reading "default" when none is active |
| `qml/widgets/Avatar.qml` | User-identity avatar — profile photo (`Config.profileImage`) masked into a disc (code screen) |
| `qml/widgets/LaunchButton.qml` | Icon-only action pill — runs the entry's `command` detached (Home / Downloads shortcuts) |
| `qml/widgets/Clock.qml` | Left clock island + calendar trigger (`compact` = time only) |
| `qml/widgets/CalendarPopup.qml` | `PopupWindow` anchored under the clock |
| `qml/widgets/CalendarView.qml` | Month calendar body (Monday-first, today/weekend/other-month states) |
| `qml/widgets/Workspaces.qml` | Center workspace pills — slot-relative, resolved through the active session band |
| `qml/widgets/SystemModule.qml` | Adaptive system pill — pure view over `Sys` (context-colored) + panel trigger |
| `qml/widgets/SystemPanel.qml` | `PopupWindow` anchored under the system pill |
| `qml/widgets/SystemPanelView.qml` | Adaptive system panel body (per-context: procs / model cards / container list / sparklines) |
| `qml/widgets/Sparkline.qml` | Canvas area+line chart (gaming panel) |
| `qml/widgets/SysTemp.qml` | CPU + GPU temperature pill — pure view over `Sys` (code screen) |
| `qml/widgets/Network.qml` | Upload + download rate pills — pure view over `Sys` (terminal screen) |
| `qml/widgets/VolumeBluetooth.qml` | Volume + Bluetooth bar pill (Pipewire + BlueZ services) + panel trigger |
| `qml/widgets/VolumeBtPanel.qml` | `PopupWindow` anchored under the volume pill |
| `qml/widgets/VolumeBtPanelView.qml` | Audio + Bluetooth control body (output, volume slider, BT toggle + device list) |

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
as bare types and every property reads `undefined`. `Sys.qml` and `Popovers.qml` are
hand-written singletons following the same rule.

## Trying it

After a rebuild the service restarts itself. To drive it by hand instead:

```sh
systemctl --user stop quickshell
qs        # or: quickshell
```

Each screen gets its role's bar (see the table above). Click a workspace pill to
switch to it; click the clock, the system pill, or the volume pill for their
popovers. Quickshell hot-reloads on file change; edits to the QML take effect on the
next rebuild.

## Notes

- Runs as a systemd user service; see [Service and restart-on-rebuild](#service-and-restart-on-rebuild)
- `Theme.qml` and `Config.qml` are generated; edit `home.nix`, not the files in
  `~/.config`.
- Metric paths in `Sys.qml` are AMD-specific: hwmon is matched by chip *name*
  (`k10temp` for CPU temp, `amdgpu` for GPU temp + package watts) and GPU load/VRAM
  come from the first DRM card exposing `gpu_busy_percent`. These are the likely
  edits on another machine.
- Hover-to-open is not wired for any popover — click to open, click again or click
  outside to close.
