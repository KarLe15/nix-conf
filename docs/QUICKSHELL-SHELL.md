# Quickshell Desktop Shell

**Status**: In progress — Stage 1 (scaffold) implemented
**Date**: 2026-07-08
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
├── home.nix           # installs quickshell-pkg; generates Theme.qml; writes shell.qml
├── README.md          # module docs
└── qml/
    └── shell.qml      # shell entry point (static, editable source)
```

### Styling pipeline

- `home.nix` reads `styleConfigs.fonts` (font families) and `styleConfigs.themes`
  (Catppuccin `flavor`) and **generates** `~/.config/quickshell/Theme.qml` — a
  `Singleton` holding the full palette, semantic aliases (`bg`/`surface`/`fg`/`accent`),
  font families, and shared metrics (`barHeight`).
- Every QML component reads from the `Theme` singleton (`import "root:/"`, then
  `Theme.<prop>`). `Theme.qml` is generated on rebuild — never edit it in `~/.config`.
- Adding a new theme flavor = add its palette to the `palettes` attrset in `home.nix`.

---

## Roadmap

| Stage | Deliverable | Replaces (eventually) | State |
|---|---|---|---|
| **1. Scaffold** | Flake input + module + enable flag + minimal `shell.qml` (per-monitor top bar with a centered clock pill). Proves wiring, theme/font injection, multi-monitor `Variants`. | — | **Done** |
| **2. Status bar** | Workspace pills + clock + system module, refactored into `widgets/` components fed by `monitors` + `workspaces` presets. Per `Status Bar` / `Screen Bars` mockups. | waybar | Not started |
| **3. System module** | Adaptive system module + hover animation. Per `System Module Hover`. | waybar | Not started |
| **4. Notifications** | Notification stack. Per `Notifications`. | swaync | Not started |
| **5. Launcher / dock** | Notch launcher + stargate dock. Per `Notch Launcher`, `App Launcher`. | rofi | Not started |
| **6. Widgets** | Calendar, system widget, side drawer, wallpaper picker. | — | Not started |
| **7. Migrate** | Add autostart (systemd user service / Hyprland `exec-once`); disable each old module once its Quickshell replacement is solid. | waybar/swaync/rofi | Not started |

---

## Current state (Stage 1)

**Implemented and syntax-validated** (`nix-instantiate --parse` on all touched files;
`Theme.qml` output rendered and inspected). Files:

- `flake.nix` — `quickshell` input + `extraSpecialArgs.quickshell-pkg`.
- `configurations/software/modules/default.nix` — `quickshell.enable` flag.
- `configurations/profiles/presets/desktop-amd.nix` — `quickshell.enable = true`.
- `homeManagerModules/default.nix` — imports `./quickshell`.
- `homeManagerModules/quickshell/{default.nix,home.nix,README.md,qml/shell.qml}`.

**Behavior**: Quickshell is installed but **not autostarted** — coexists with Waybar.
`shell.qml` draws a transparent top bar per monitor with a centered Macchiato clock
pill (Meslo mono, `ddd dd MMM HH:mm`).

### Verify

```sh
sudo nixos-rebuild switch --flake .#mastodant1   # first build compiles Quickshell from source (slow)
qs                                                # launch manually inside Hyprland; Ctrl-C to stop
```

Expect a clock pill centered in a top bar on each of the 3 screens.

### Not yet done / open items

- **Not build-tested here** — the rebuild needs sudo and compiles Quickshell on the
  target machine. `flake.lock` gains the `quickshell` entry on first build.
- **Singleton import** (`import "root:/"`) is the one piece untested live; syntax can
  differ across Quickshell versions. If `qs` errors there, it's a one-line fix.
- **No autostart** until Stage 7.
- **`.qmlls.ini`** (QML language-server) intentionally not wired, to keep the config
  dir clean.
