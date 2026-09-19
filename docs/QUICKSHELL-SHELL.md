# Quickshell Desktop Shell

**Status**: In progress — Stages 1–3 done, plus several Stage 6 widgets
**Date**: 2026-08-30
**Module**: `homeManagerModules/quickshell/`
**Preset**: `configurations/style/quickshell/`
**Design source**: Claude Design project "Quickshell Desktop Shell Design"
(`claude.ai/design/p/06a5ef08-04d4-41d7-a578-3f2d2e96c804`)

---

## Goal

Port the "Quickshell Desktop Shell" design (a set of HTML/CSS mockups) into a real
[Quickshell](https://quickshell.org) (QtQuick/QML) desktop shell, packaged as a Home
Manager module that follows this repo's conventions (profile system, feature flags,
preset-driven styling, per-module docs). Built **surface by surface**, each gated
behind one enable flag and themed from the existing presets.

---

## Key decisions

| Decision | Choice | Rationale |
|---|---|---|
| First target | **Desktop 3-screen** (`mastodant1` / `desktop-amd`) | The only active host; the shell runs on the next rebuild |
| Quickshell source | **Upstream flake input** (`git+https://git.outfoxxed.me/outfoxxed/quickshell`, follows nixpkgs) | Latest features, matches upstream docs |
| Migration strategy | **Coexist first, migrate later** | Build alongside Waybar/Swaync/Rofi; flip each old module off only once its replacement is solid |
| Fonts | From `styleConfigs.fonts` preset (**Meslo Nerd Font**) | Follow the repo's decisions, not the mockup's JetBrains Mono / IBM Plex |
| Colors | Catppuccin palette keyed by `styleConfigs.themes` flavor, hexes matching `status-bars/assets/style.css` | Quickshell and Waybar render identical hues during coexistence |
| Bar composition | **Data-driven**, from a `configurations/style/quickshell/` preset | Per-screen layout is config, not code; the module never reaches up into `configurations/` |
| System metrics | **One `Sys` singleton**, not per-widget pollers | A singleton is process-global, so 3 bars cost one poller set; widgets stay pure views |

---

## Design DNA (from the Claude Design project)

- **Stack**: Quickshell on Hyprland, Catppuccin **Macchiato**.
- **Visual language**: floating "mantle" islands / pills, colorful filled pills, an
  adaptive system module, a "stargate" dock, and a top-center notch launcher.
- **Two setups in the design**:
  1. **Desktop** (original) — 3-monitor ultrawide rig: two 1920×1080 side by side
     (3840 wide) + one 3440×1440 on top. *(This is what we build first.)*
  2. **MacBook Pro M1 Pro 14" / Asahi Linux** — single notched display, bar hugs the
     real notch. No host exists for this in the repo yet.
- **Component surfaces** (each a `.dc.html` mockup): Screen Bars, Status Bar, System
  Widget, App Launcher, Notch Launcher, Notifications, Side Drawer, Calendar Widget,
  System Module Hover, Wallpaper Pick Animation.

---

## Architecture

### Wiring (how the module plugs in)

Same chain as every other module (`hyprland`, `waybar`):

1. `flake.nix` — `quickshell` input added; the built package is passed to Home Manager
   via `home-manager.extraSpecialArgs.quickshell-pkg = quickshell.packages.${system}.default`.
   *(Note: home modules list `inputs` in their signature but never dereference it —
   `extraSpecialArgs` is the real channel, so the package is passed explicitly.)*
2. `configurations/software/modules/default.nix` — declares
   `software.modules.quickshell.enable` and `software.modules.quickshell.bars`.
3. `configurations/style/default.nix` — imports `./quickshell`, declaring
   `style.quickshell.active` (the layout preset selector).
4. `custom-config-generator.nix` — resolves that selector to
   `configurations/style/quickshell/presets/<active>.nix` and exposes it as
   `customConfigs.styleConfigs.quickshell`.
5. `homeManagerModules/default.nix` — imports `./quickshell`.
6. `configurations/profiles/presets/desktop-amd.nix` — sets `quickshell.enable = true`
   and `style.quickshell.active = "screen-bars"`.
7. `homeManagerModules/quickshell/` — the module, gated on
   `cfg = customConfigs.softwareConfigs.modules.quickshell` via `lib.mkIf cfg.enable`.

### Module layout

```
homeManagerModules/quickshell/
├── default.nix        # thin wrapper → imports home.nix
├── home.nix           # installs quickshell-pkg; generates Theme.qml + Config.qml; writes the QML tree
├── README.md          # module docs
├── scripts/
│   └── context.sh     # context probe (GameMode / ollama / docker / systemd)
└── qml/
    ├── shell.qml               # entry point — one Bar per screen via Variants
    ├── Bar.qml                 # per-monitor PanelWindow — 3 zones, each a Repeater over the layout
    ├── Sys.qml                 # singleton — system metrics + context (the only thing that polls)
    ├── Popovers.qml            # singleton — popover dismissal (one-at-a-time + click-outside)
    └── widgets/
        ├── WidgetSlot.qml      # dispatches one layout entry to its widget
        ├── StubPill.qml        # design stub for not-yet-built modules
        ├── Avatar.qml          # profile-photo disc
        ├── LaunchButton.qml    # icon-only pill that runs a command
        ├── Clock.qml           # clock island + calendar trigger
        ├── CalendarPopup.qml   # PopupWindow under the clock
        ├── CalendarView.qml    # month calendar body
        ├── Workspaces.qml      # workspace pills (Hyprland-driven)
        ├── SystemModule.qml    # adaptive context pill + panel trigger
        ├── SystemPanel.qml     # PopupWindow under the system pill
        ├── SystemPanelView.qml # adaptive panel body (per-context)
        ├── Sparkline.qml       # Canvas area+line chart
        ├── SysTemp.qml         # CPU + GPU temperature pill
        ├── Network.qml         # upload / download rate pills
        ├── VolumeBluetooth.qml # volume + Bluetooth pill + panel trigger
        ├── VolumeBtPanel.qml   # PopupWindow under the volume pill
        └── VolumeBtPanelView.qml # audio + Bluetooth control body
```

### Styling pipeline

- `home.nix` reads `styleConfigs.fonts` (font families) and `styleConfigs.themes`
  (Catppuccin `flavor`) and **generates** `~/.config/quickshell/Theme.qml` — a
  `Singleton` holding the full palette, semantic aliases (`bg`/`surface`/`fg`/`accent`),
  font families, the date/time `locale`, and shared metrics (`barHeight`, pill sizes).
- `home.nix` also **generates** `~/.config/quickshell/Config.qml` — a `Singleton`
  holding the per-monitor workspace layout (`{ id, icon, monitor }`) projected from
  the `workspaces`/`monitors` presets, the connector→role map (`roles`), `hubMonitor`
  (the ultrawide), the per-screen `barLayout`, and the avatar `profileImage` path.
- Every QML component reads from the `Theme` / `Config` singletons (`import "root:/"`,
  then `Theme.<prop>` / `Config.<prop>`). Both are generated on rebuild — never edit
  them in `~/.config`.
- Adding a new theme flavor = add its palette to the `palettes` attrset in `home.nix`.

### Data-driven bar composition

The bar is **layout data, not code**. `configurations/style/quickshell/presets/screen-bars.nix`
exports a `bars` attrset keyed by monitor **role** (`code` / `terminal` / `browser` /
`other`); each role has `left` / `center` / `right` lists of entries:

```nix
{ w = "clock"; compact = true; }                                   # a real widget
{ w = "action"; icon = "f015"; color = "blue"; command = "…"; }    # launches a command
{ w = "stub"; icon = "f11c"; label = "resize"; color = "peach"; }  # design placeholder
```

| Key | Meaning |
|---|---|
| `w` | Widget name — dispatched by `qml/widgets/WidgetSlot.qml` |
| `icon` | Nerd Font codepoint (hex, no backslash) — serialized as `\uXXXX` |
| `label` | Text beside the glyph |
| `color` | `Theme` palette name (`peach`, `sapphire`, …) |
| `command` | Shell command for `w = "action"` — run detached |
| `compact` | Clock shows time only (no date) |
| `dashed` | Stub drawn with a dashed ring (conditional pills) |

`home.nix` serializes that attrset into `Config.barLayout`; `Bar.qml` picks its role's
entry and each zone is a `Repeater` over the list. Recognised widget names are `clock`,
`workspaces`, `system`, `systemp`, `network`, `volume`, `avatar`, `action` — **anything
else falls back to a `StubPill`** built from the entry's `icon`/`label`/`color`, so the
design's not-yet-built modules render immediately with no backend.

Adding a real widget = write the QML component, add a case in `WidgetSlot.qml`, and
name it in the preset. A host can override the whole map via
`software.modules.quickshell.bars` (empty = use the preset).

The preset also owns `profile-image` (the avatar photo) and builds its launch-action
commands from `softwareConfigs.defaults` (the repo's single source of truth for the
file explorer, terminal, …) rather than hardcoding a binary.

### System metrics: the `Sys` singleton

`qml/Sys.qml` is a `pragma Singleton` and therefore **process-global** — one instance
serves all three bars. It is the only component that talks to the system; every widget
(`SystemModule`, `SysTemp`, `Network`, and the panels) is a pure view reading
`Sys.<prop>`. Three pollers:

| Poller | Interval | Source | Provides |
|---|---|---|---|
| metrics | 2 s | `/proc/stat`, `/proc/meminfo`, `/proc/net/dev`, `/sys/class/hwmon/*` (`k10temp`, `amdgpu`), `/sys/class/drm/card*/device` | CPU %, CPU/GPU temp, GPU %, GPU watts, RAM, VRAM, net rx/tx |
| context | 5 s | `scripts/context.sh` | context, systemd running/failed, ollama models, docker containers |
| procs | 5 s | `ps` | top-3 CPU processes |

The metrics poller is a **single shell one-shot** that echoes every number on one line,
so a snapshot is internally consistent. `Sys` also keeps a rolling 40-sample history
(`cpuHist` / `gpuHist` / `ramHist` / `netHist`) for the gaming sparklines.

This boundary is deliberate: a future socket/DBus daemon can push into these same
properties without touching a single widget.

**Exception**: audio and Bluetooth do *not* go through `Sys` — `VolumeBluetooth` binds
Quickshell's own `Quickshell.Services.Pipewire` and `Quickshell.Bluetooth` services
directly (live objects, no polling at all).

### Popover management

`qml/Popovers.qml` (singleton) coordinates the drop-down panels (calendar, system,
volume/Bluetooth), giving them two behaviours raw `PopupWindow`s lack:

- **one-open-at-a-time** — each popup binds `visible: Popovers.active === <self>`, so
  opening one closes any other;
- **click-outside dismiss** — a `HyprlandFocusGrab` covers the open popover *and every
  registered bar*. Including the bars means clicking another chip is not an
  outside-click: it reaches that chip and swaps the popover in one click, instead of
  the grab eating the first click.

Each `Bar` registers itself on completion and unregisters on destruction.

> **Singleton gotcha (resolved).** Quickshell singletons need a real `pragma Singleton`
> statement, **not** the `//@ pragma Singleton` *comment*. With the comment form the
> engine registers `Theme`/`Config` as bare types and every property reads `undefined`.
> Verified headlessly with `QT_QPA_PLATFORM=offscreen qs -p <dir>` before rebuilding.

---

## Roadmap

| Stage | Deliverable | Replaces (eventually) | State |
|---|---|---|---|
| **1. Scaffold** | Flake input + module + enable flag + minimal `shell.qml` (per-monitor top bar with a centered clock pill). Proves wiring, theme/font injection, multi-monitor `Variants`. | — | **Done** |
| **2. Status bar** | Workspace pills + clock + basic system module, refactored into `widgets/` components fed by `monitors` + `workspaces` presets. Per the `Screen Bars` mockup (solid Crust bar, filled pills). Later made **data-driven**: per-screen composition from a `configurations/` preset, with `StubPill` standing in for unbuilt modules. | waybar | **Done** |
| **3. System module** | Adaptive context pill (gaming/llm/container/standard) + click-to-open unified panel with per-context bodies (top procs / model cards / container list / sparklines). Metrics centralised in the `Sys` singleton. Hover-to-open animation still to come (click only). | waybar | **Done** |
| **4. Notifications** | Notification stack. Per `Notifications`. | swaync | Not started |
| **5. Launcher / dock** | Notch launcher + stargate dock. Per `Notch Launcher`, `App Launcher`. | rofi | Not started |
| **6. Widgets** | Calendar, volume/Bluetooth, temperatures, network, launch actions, avatar, side drawer, wallpaper picker. | — | Calendar, volume/BT, CPU+GPU temps, net rates, launch buttons, avatar **done**; side drawer + wallpaper picker not started |
| **7. Migrate** | Autostart via a systemd user service with `X-Restart-Triggers`, so a rebuild restarts the shell; disable each old module once its Quickshell replacement is solid. | waybar/swaync/rofi | **Waybar + avizo done**; swaync/rofi outstanding |

---

## Current state

**Design chosen**: the **`Screen Bars` · Filled** direction — a solid Crust bar with
colored, dark-on-accent filled pills (not the floating-islands `Status Bar` mockup).
Accent is **mauve**.

**Behavior**: runs as a managed user service bound to `graphical-session.target`;
Waybar and avizo are disabled.
Every monitor gets a solid top bar with a hairline bottom border and three zones, and
each screen now carries a **different** composition driven by its role:

| Screen (role) | left | center | right |
|---|---|---|---|
| **browser** (ultrawide hub) | clock (time + date) · DND, REC, submap, idle-inhibitor stubs | workspaces | system module · GameMode + scheduler stubs · volume/BT · notification stub |
| **code** (primary) | avatar · Home + Downloads launch buttons | workspaces | submap stub · CPU/GPU temps · volume/BT |
| **terminal** | clock (compact) · submap stub | workspaces | LLM stub (dashed) · net up/down |
| **other** (unmapped) | clock (compact) | workspaces | system module · volume/BT |

Workspace ids/glyphs come from the repo's `workspaces` preset (monitor binding code →
1/4/7, terminal → 2/5/8, browser → 3/6/9); live focus and occupancy come from Hyprland,
and pills are click-to-switch. The focused workspace is highlighted consistently across
every bar.

Three popovers are wired, all mutually exclusive and dismissed by clicking outside:
the **calendar** (from the clock), the **system panel** (per-context body), and the
**volume/Bluetooth controls** (output, volume slider, BT toggle, device list with
connect/battery/scan).

### How it is validated (offline, no compositor)

Quickshell runs on Qt's QML engine, so the config is loaded headlessly:

```sh
QT_QPA_PLATFORM=offscreen qs -p <tmp>/shell.qml        # parses shell.qml + Bar.qml (fails only at
                                                        # "No PanelWindow backend" — needs Wayland)
QT_QPA_PLATFORM=offscreen qs -p <tmp>/check.qml         # a harness loading the widgets WITHOUT a
                                                        # PanelWindow → type-checks the components +
                                                        # resolves Theme/Config
```

This caught the singleton bug (comment `//@ pragma` → every `Theme.*` was `undefined`;
fixed to real `pragma Singleton`) and confirmed `Theme`/`Config` resolve with correct
values (`ws=9`, `hubMonitor=HDMI-A-2`, `accent=#c6a0f6`). `Config.qml` generation is
also checked via `nix eval`. `nix-instantiate --parse` passes on the Nix files.

### Verify on target

```sh
sudo nixos-rebuild switch --flake .#mastodant1   # first build compiles Quickshell from source (slow)
qs                                                # launch manually inside Hyprland; Ctrl-C to stop
```

### Not build-tested here / open items

- **PanelWindow rendering, live Hyprland data, Pipewire/BlueZ services, and the
  `HyprlandFocusGrab`** need the real desktop — none can be exercised headlessly (no
  Wayland/layer-shell, no Hyprland socket, no session bus). Everything up to window
  creation is validated.
- **Hardware-specific metric paths**: `Sys.qml` reads hwmon by chip *name* (`k10temp`
  for CPU, `amdgpu` for GPU/watts) and takes the first DRM card exposing
  `gpu_busy_percent` — correct for this AMD host, and the likely edit on any other.
- **`context.sh` probes** GameMode over the session bus, ollama on
  `127.0.0.1:11434`, and `docker`; each degrades to "absent" when the service isn't
  there, so the context falls back to `standard`.
- **Stubs are inert**: DND, REC, submap, idle-inhibitor, GameMode, scheduler, the
  notification count, and the troll pill render from layout data with **no backend**.
  Each becomes real by adding a component + a `WidgetSlot` case.
- **Hover-to-open** is not wired for any popover (click to open, click again or
  outside to close). The `System Module Hover` mockup's animation is still to come.
- **No autostart** until Stage 7. **`.qmlls.ini`** still intentionally not wired.
