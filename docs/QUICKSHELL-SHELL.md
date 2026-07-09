# Quickshell Desktop Shell

**Status**: In progress — Stage 2 (status bar) implemented
**Date**: 2026-07-09
**Module**: `homeManagerModules/quickshell/`
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
2. `configurations/software/modules/default.nix` — declares `software.modules.quickshell.enable`.
3. `homeManagerModules/default.nix` — imports `./quickshell`.
4. `configurations/profiles/presets/desktop-amd.nix` — sets `quickshell.enable = true`.
5. `homeManagerModules/quickshell/` — the module, gated on
   `cfg = customConfigs.softwareConfigs.modules.quickshell` via `lib.mkIf cfg.enable`.

### Module layout

```
homeManagerModules/quickshell/
├── default.nix        # thin wrapper → imports home.nix
├── home.nix           # installs quickshell-pkg; generates Theme.qml + Config.qml; writes the QML tree
├── README.md          # module docs
└── qml/
    ├── shell.qml               # entry point — one Bar per screen via Variants
    ├── Bar.qml                 # per-monitor PanelWindow (solid bar, 3 zones)
    └── widgets/
        ├── Clock.qml           # left clock island
        ├── Workspaces.qml      # center workspace pills (Hyprland-driven)
        └── SystemModule.qml    # right system pills (CPU/temp + volume)
```

### Styling pipeline

- `home.nix` reads `styleConfigs.fonts` (font families) and `styleConfigs.themes`
  (Catppuccin `flavor`) and **generates** `~/.config/quickshell/Theme.qml` — a
  `Singleton` holding the full palette, semantic aliases (`bg`/`surface`/`fg`/`accent`),
  font families, and shared metrics (`barHeight`).
- `home.nix` also **generates** `~/.config/quickshell/Config.qml` — a `Singleton`
  holding the per-monitor workspace layout (`{ id, icon, monitor }`) projected from
  the `workspaces`/`monitors` presets, plus `hubMonitor` (the ultrawide). The bar's
  workspace pills read their id/glyph/monitor from here; live focus and occupancy
  come from Hyprland at runtime.
- Every QML component reads from the `Theme` / `Config` singletons (`import "root:/"`,
  then `Theme.<prop>` / `Config.<prop>`). Both are generated on rebuild — never edit
  them in `~/.config`.
- Adding a new theme flavor = add its palette to the `palettes` attrset in `home.nix`.

> **Singleton gotcha (resolved).** Quickshell singletons need a real `pragma Singleton`
> statement, **not** the `//@ pragma Singleton` *comment*. With the comment form the
> engine registers `Theme`/`Config` as bare types and every property reads `undefined`.
> Verified headlessly with `QT_QPA_PLATFORM=offscreen qs -p <dir>` before rebuilding.

---

## Roadmap

| Stage | Deliverable | Replaces (eventually) | State |
|---|---|---|---|
| **1. Scaffold** | Flake input + module + enable flag + minimal `shell.qml` (per-monitor top bar with a centered clock pill). Proves wiring, theme/font injection, multi-monitor `Variants`. | — | **Done** |
| **2. Status bar** | Workspace pills + clock + basic system module, refactored into `widgets/` components fed by `monitors` + `workspaces` presets. Per the `Screen Bars` mockup (solid Crust bar, filled pills). | waybar | **Done** |
| **3. System module** | Adaptive system module + hover animation. Per `System Module Hover`. | waybar | Not started |
| **4. Notifications** | Notification stack. Per `Notifications`. | swaync | Not started |
| **5. Launcher / dock** | Notch launcher + stargate dock. Per `Notch Launcher`, `App Launcher`. | rofi | Not started |
| **6. Widgets** | Calendar (**done** — clock-triggered month popover, per-screen clock format), system widget, side drawer, wallpaper picker. | — | Calendar done; rest not started |
| **7. Migrate** | Add autostart (systemd user service / Hyprland `exec-once`); disable each old module once its Quickshell replacement is solid. | waybar/swaync/rofi | Not started |

---

## Current state (Stage 2)

**Design chosen**: the **`Screen Bars` · Filled** direction — a solid Crust bar with
colored, dark-on-accent filled pills (not the floating-islands `Status Bar` mockup).
Accent is **mauve**.

**Implemented and validated**. New/changed files:

- `homeManagerModules/quickshell/home.nix` — now also reads the `monitors` +
  `workspaces` presets, generates `Config.qml`, and emits the expanded `Theme.qml`
  palette/aliases/metrics. Writes the `qml/` tree.
- `homeManagerModules/quickshell/qml/{shell.qml,Bar.qml,widgets/{Clock,Workspaces,SystemModule}.qml}`.
- `homeManagerModules/quickshell/README.md` — Stage 2 docs.

**Behavior**: still **not autostarted** — coexists with Waybar. Per monitor: a solid
top bar with a clock island (left), the full 1–9 workspace strip (center, live from
Hyprland, click-to-switch; the focused workspace is highlighted consistently across
every bar), and a system module (right: CPU/temp + volume). Workspace ids/glyphs come
from the repo's `workspaces` preset (monitor binding code → 1/4/7, terminal → 2/5/8,
browser → 3/6/9).

### How it was validated (offline, no compositor)

Quickshell runs on Qt's QML engine, so the config was loaded headlessly:

```sh
QT_QPA_PLATFORM=offscreen qs -p <tmp>/shell.qml        # parses shell.qml + Bar.qml (fails only at
                                                        # "No PanelWindow backend" — needs Wayland)
QT_QPA_PLATFORM=offscreen qs -p <tmp>/check.qml         # a harness loading the widgets WITHOUT a
                                                        # PanelWindow → type-checks Clock/Workspaces/
                                                        # SystemModule + resolves Theme/Config
```

This caught the singleton bug (comment `//@ pragma` → every `Theme.*` was `undefined`;
fixed to real `pragma Singleton`) and confirmed `Theme`/`Config` resolve with correct
values (`ws=9`, `hubMonitor=HDMI-A-2`, `accent=#c6a0f6`). `Config.qml` generation was
also checked via `nix eval`. `nix-instantiate --parse` passes on the Nix files.

### Verify on target

```sh
sudo nixos-rebuild switch --flake .#mastodant1   # first build compiles Quickshell from source (slow)
qs                                                # launch manually inside Hyprland; Ctrl-C to stop
```

Expect a solid top bar on each of the 3 screens: clock left, workspace pills center
(active one filled lavender), CPU/temp + volume right. Clicking a pill switches
workspace.

### Not build-tested here / open items

- **PanelWindow rendering + live Hyprland/volume data** need the real desktop — can't
  be exercised headlessly (no Wayland/layer-shell, no Hyprland socket). Everything
  up to window creation is validated.
- **Calendar popover (`CalendarPopup`)**: the `PopupWindow` positioning + click-to-open
  need the live compositor; only the `CalendarView` body (grid, today/weekend/
  other-month, ISO weeks, nav) is validated headlessly. The clock format is
  per-screen: the hub (ultrawide) shows time + date, side screens show time only,
  driven by `bar.isHub`. Outside-click-to-close and hover-to-open are not wired
  (click the clock again to close).
- **System module** polls `/proc/stat`, `thermal_zone0`, and `wpctl` every 2s. The
  thermal-zone path and `wpctl` availability are the likely per-machine tweaks.
- **Per-monitor roles**: the *routing* is now wired — `Config.roles` maps each
  connector name to `code`/`terminal`/`browser`, and `Bar.qml` exposes `role` +
  `isHub`. Module *content* is still identical on every bar; the mockup's per-role
  modules (hub-only global modules, REC/DND/submap, bandwidth, troll, identity) slot
  in behind `bar.isHub` / `bar.role` as they land in later stages.
- **No autostart** until Stage 7. **`.qmlls.ini`** still intentionally not wired.
