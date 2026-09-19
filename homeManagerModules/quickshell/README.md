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
| **browser** (ultrawide hub) | session · clock (time + date) · presence mirror · REC stub · submap · idle mirror | workspaces | system module · GameMode + scheduler stubs · volume/BT · notification mirror |
| **code** (primary) | session · avatar (presence ring + control centre) · Home + Downloads launch buttons | workspaces | submap · CPU/GPU temps · volume/BT |
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
- **avatar** — profile photo masked into a disc whose **ring carries presence**
  (green available, yellow focus, red DND). Click drops the **control centre**:
  identity, the presence switch, the idle inhibitor with duration chips, the network
  block and a facts block. See [Presence, idle and network](#presence-idle-and-network).
- **presence / idle / notifications** — read-only `MirrorPill`s on the hub bar that
  echo that same state. No click targets: the popover is the only place any of it
  changes. The notification pill hides itself when the count is zero.
- **action** — icon-only pill that runs a shell command detached (Home / Downloads
  shortcuts, built from the repo's default file explorer).

Anything else in the layout renders as a **`StubPill`**: a design placeholder with no
backend, so unbuilt modules (REC, GameMode, scheduler, the troll pill) already appear
in the right place.

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
  per-screen `barLayout`, the OSD / command-palette / avatar blocks, and the avatar
  image path.
- Writes the static QML component tree (`shell.qml`, `Bar.qml`, `Sys.qml`,
  `Popovers.qml`, `Presence.qml`, `Idle.qml`, `Osd.qml`, `CommandPalette.qml`,
  `widgets/*.qml`), the `scripts/` helpers, and the avatar photo.

## Bar layout

Each zone entry is an attrset dispatched by `qml/widgets/WidgetSlot.qml`:

```nix
{ w = "clock"; compact = true; }                                   # a real widget
{ w = "action"; icon = "f015"; color = "blue"; command = "…"; }    # launches a command
{ w = "stub"; icon = "f11c"; label = "resize"; color = "peach"; }  # design placeholder
```

| Key | Meaning |
|---|---|
| `w` | Widget name: `clock`, `workspaces`, `session`, `submap`, `system`, `systemp`, `network`, `volume`, `avatar`, `presence`, `idle`, `notifications`, `action` — anything else (notably `stub`) falls back to `StubPill` |
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
| facts | 30 s | `/proc/uptime`, `uname`, `ip -4 -o addr` | uptime, kernel, host, ifname→IPv4 map (avatar popover) |

The metrics poller is one shell one-shot echoing every number on a single line, so a
snapshot is internally consistent; `Sys` also keeps a rolling 40-sample history for
the gaming sparklines. The boundary is deliberate — a future socket/DBus daemon could
push into these same properties without touching a widget.

**Audio and Bluetooth bypass `Sys`**: `VolumeBluetooth.qml` binds Quickshell's own
`Quickshell.Services.Pipewire` and `Quickshell.Bluetooth` services (live objects, no
polling).


## Presence, idle and network

The avatar widget is a photo disc (`AvatarDisc.qml`) whose ring carries presence, and
a click-through to the control centre (`AvatarPanel` → `AvatarPanelView`). Three
backends sit behind it, none of them polled by `Sys`:

| State | Singleton | Source |
|---|---|---|
| presence + notification count | `qml/Presence.qml` | `swaync-client -swb` subscription (JSON lines) |
| keep-awake hold | `qml/Idle.qml` | wayland `IdleInhibitor`, instantiated on each `Bar` |
| interfaces, SSIDs, radio | — (bound directly) | `Quickshell.Networking` (NetworkManager) |

**Presence.** swaync stays the source of truth: the subscription emits on connect and
on every add/close/DND change, so a `swaync-client -d` typed in a terminal moves the
ring too. `Presence.set()` fires `-dn`/`-df` and lets the subscription confirm rather
than caching a state the daemon might disagree with; an exit re-subscribes after 2 s,
so a swaync restart reconnects. **Focus and DND both mean "swaync DND on"** — swaync
cannot filter per application, so a Focus that "mutes chat and mail" would be a lie.
Real Focus rules arrive with the notification centre that replaces swaync (Stage 4),
and Focus collapses to DND across a shell restart because the daemon reports only
silenced/not-silenced.

**Idle.** `Idle.qml` owns the decision and the countdown; the wayland object that
holds the machine awake needs a *visible* window, so it lives in `Bar.qml` as
`IdleInhibitor { window: bar; enabled: Idle.enabled }` — one per bar, which is
redundant but harmless. Inhibiting goes through the compositor, so Hyprland stops
emitting idle and hypridle's lock / dpms / suspend timers never fire; the service is
left alone and its schedule resumes when the hold drops. The "sleeps after 10m"
subtitle is `powermanagement.idleTimeouts.lockAfter`, the same number the hypridle
module renders.

**Network.** Quickshell 0.3 ships a NetworkManager-backed `Quickshell.Networking`, so
no `nmcli`. The block follows design variant 10b: interfaces as peers with a check on
whichever carries the default route, and the ethernet row hidden while `hasLink` is
false (the artboard only draws the plugged case; this host lives on Wi-Fi). Two
behaviours worth knowing:

- **The scanner is gated on the popover.** NetworkManager reports only the connected
  AP until something asks it to scan — with the scanner off the list is one row. The
  view binds `scannerEnabled` to its own visibility, so the radio isn't scanning for a
  panel nobody is looking at. There is no one-shot scan in the API.
- **No PSK, by decision.** Saved networks (`WifiNetwork.known`) carry a `saved` chip
  and connect on click; unsaved ones are listed dimmed and inert. Joining a new SSID
  is a terminal job. A password field would also need keyboard focus, which a
  `PopupWindow` under a non-focusable bar cannot take.

`NetworkDevice.address` is the **MAC**, not the IP — the popover's `· 192.168.4.17`
comes from a `Sys` facts poller (30 s: uptime, kernel, host, ifname→IPv4 map), which
also feeds the facts block.

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

`qml/Popovers.qml` (singleton) coordinates the drop-downs — calendar, system panel,
volume/Bluetooth and the avatar control centre — so that only one is open at
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
| `styleConfigs.quickshell` | `.apply { pkgs, default-programs } → .bars`, `.profile-image`, `.osd`, `.palette`, `.avatar` | Per-screen bar layout, avatar photo, OSD / command-palette / avatar-widget config |
| `softwareConfigs.powermanagement` | `.apply { pkgs } → .idleTimeouts.lockAfter` | The "sleeps after 10m" line in the avatar popover — the same schedule hypridle runs |
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
| `qml/Presence.qml` | Singleton — presence + notification count, subscribed to `swaync-client -swb`; `set()` drives swaync DND |
| `qml/Idle.qml` | Singleton — keep-awake decision, selected duration and countdown; the wayland inhibitor itself lives on each `Bar` |
| `qml/Osd.qml` | Multimedia OSD — volume/mic overlay fired by Pipewire changes (card / ring / notch variants) |
| `qml/CommandPalette.qml` | Command palette — apps + clipboard modes, global shortcuts, exclusive keyboard focus while open |
| `qml/widgets/WidgetSlot.qml` | Dispatches one layout entry (`{ w, … }`) to its widget, or a `StubPill` fallback |
| `qml/widgets/StubPill.qml` | Static design stub pill (icon/label/palette-color from layout data) for not-yet-built widgets |
| `qml/widgets/SessionPill.qml` | Workspace-session indicator — active session + the open ones, derived from workspace ids; click to switch |
| `qml/widgets/SubmapPill.qml` | Active-submap indicator — name from the raw Hyprland IPC `submap` event; always visible, reading "default" when none is active |
| `qml/widgets/Avatar.qml` | Bar avatar trigger — the disc plus the click that drops the control centre |
| `qml/widgets/AvatarDisc.qml` | The disc itself — photo (`Config.profileImage`) masked into a circle, ringed in the presence colour; reused at 52 px in the popover |
| `qml/widgets/AvatarPanel.qml` | `PopupWindow` anchored under the avatar; passes its visibility down to gate the Wi-Fi scanner |
| `qml/widgets/AvatarPanelView.qml` | Control-centre body — identity, presence switch, idle inhibitor + chips, network (variant 10b), facts |
| `qml/widgets/MirrorPill.qml` | Read-only hub-bar echo of presence / idle / notification count — no actions |
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
| `qml/widgets/OsdCard.qml`, `OsdRing.qml`, `OsdNotch.qml` | The three OSD variants selected by the preset `osd.variant` |
| `qml/widgets/PaletteRow.qml` | Mode-agnostic command-palette row (icon, title, subtitle, hint, selection style) |

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
switch to it; click the clock, the system pill, the volume pill or the avatar for
their popovers. Quickshell hot-reloads on file change; edits to the QML take effect on the
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
- The avatar widget depends on `swaync-client` being on `PATH` (it is, via the swaync
  module). With swaync stopped the ring simply stays green and the subscription retries
  every 2 s.
- `Quickshell.Networking` needs NetworkManager (`networking.networkmanager.enable`).
  The Wi-Fi rows disappear on a host with no wireless device; the ethernet row appears
  only while a cable is live.
