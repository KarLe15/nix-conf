# NixOS Configuration — Project Summary

**Version**: 0.1.0
**Date**: 2026-03-19
**Commit**: fe4be38

## Overview

Personal NixOS configuration for a single AMD gaming/development desktop (`mastodant1`, hostname `karle`). The defining architectural feature is a **preset/profile system** that makes the config machine-agnostic: each host selects named presets by string ID, a resolver (`custom-config-generator.nix`) injects the resolved data as `customConfigs` into all Home Manager modules.

A Darwin host (`mac-m1`) is fully scaffolded in `flake.nix` but commented out; infrastructure is in place for future multi-machine use.

---

## Directory Layout

```
config/
├── flake.nix                      # Main entrypoint — defines all system outputs
├── flake.lock
├── custom-config-generator.nix    # Preset resolver (pure Nix, not a module)
├── hosts/                         # Per-machine NixOS system configs
│   └── mastodant-1/
├── homeManagerModules/            # All Home Manager module library
├── nixCommonModules/              # Shared NixOS + Darwin modules (cursor, stylix, secrets)
├── nixosModules/                  # NixOS-only modules (currently empty stubs)
├── nixDarwinModules/              # Darwin-only modules (currently empty stubs)
├── configurations/                # Pure-data preset library (hardware/style/software)
├── secrets_store/                 # ragenix-encrypted .age secrets
└── local_secrets/                 # Local (untracked) secrets
```

---

## Active Host: `mastodant1`

| Property | Value |
|---|---|
| Architecture | `x86_64-linux` |
| User | `karim` |
| Hostname | `karle` |
| State version | `24.11` |
| GPU | AMD |
| Displays | 3-monitor (1× ultrawide 3440×1440@100Hz + 2× 1920×1080@60Hz) |
| Shell | Fish |
| Desktop | Hyprland (via UWSM + SDDM) |

### Host Config Files (`hosts/mastodant-1/`)

| File | Purpose |
|---|---|
| `configuration.nix` | Top-level imports, bootloader (systemd-boot) |
| `options.nix` | Preset selections for this machine |
| `kernel.nix` | AMD GPU modules, suspend/power params, gaming sysctl |
| `services-configuration.nix` | SDDM, GNOME packages (no GDM), PipeWire, printing |
| `networks.nix` | Hostname, NetworkManager, ZFS hostId |
| `locales.nix` | TZ Europe/Paris, English locale, French LC_ overrides, FR keyboard |
| `security.nix` | rtkit, PAM for hyprlock |
| `users.nix` | User `karim`, fish shell, groups: docker/networkmanager/wheel/input |
| `programs.nix` | Firefox, Hyprland (flake), fish |
| `gaming.nix` | Full gaming stack (see Gaming section) |
| `developpement.nix` | Docker + Podman, dive, podman-tui |
| `filesystems.nix` | Multi-drive storage |

---

## Preset System

The project's most distinctive design. Rather than inline configuration, each host declares what "profile" it uses:

```nix
# hosts/mastodant-1/options.nix
hardware.monitors.active    = "mastodant-3-screens";
style.themes.active         = "catppuccin-macchiato";
software.defaults.active    = "mastodant-1";
software.shortcuts.active   = "mastodant-1";
# ... etc.
```

`custom-config-generator.nix` resolves these string names to their actual Nix data by importing `configurations/<domain>/presets/<name>.nix`. The resolved `customConfigs` attrset is threaded as a `specialArg` into every Home Manager module — pure data injection, no NixOS option evaluation.

Each preset file exports an `apply` function (`{ pkgs, ... }: { ... }`) and an `autostart` list.

### Preset Categories (`configurations/`)

| Domain | Presets |
|---|---|
| `hardware/monitors` | `mastodant-3-screens` — 3-monitor layout with roles |
| `style/themes` | `catppuccin-macchiato` — base16 scheme |
| `style/fonts` | `mac-like` — Meslo Nerd Font family |
| `style/cursors` | `Bibata` |
| `style/wallpapers` | `standard` |
| `style/workspaces` | `standard-3-screen` — 9 workspaces across 3 monitors |
| `style/status-bars` | `waybar-3-screen` — 4-bar Waybar layout |
| `software/defaults` | `mastodant-1` — default browser/terminal/editor/launcher |
| `software/shortcuts` | `mastodant-1` — full Hyprland keybindings |
| `software/git-accounts` | `standard` — 3 git identities (GitHub personal, GitLab personal, GitLab work) |
| `software/launchers` | `rofi` — Rofi + cliphist autostart |
| `software/powermanagement` | `systemD` — systemctl commands |
| `software/multimedia` | `avizo` — volumectl commands |

### Type System (`configurations/`)

Preset output types are co-located with their domain and aggregated through a single file:

```
configurations/
├── lib/
│   └── types.nix            # Shared primitives: packageType, appDefType, appDefWithEnvType
├── types.nix                # Flat aggregator — single import point for custom-config-generator.nix
├── hardware/monitors/
│   └── types.nix            # monitorDefType, monitorsOutputType
├── style/
│   ├── fonts/types.nix      # fontDefType, fontsOutputType
│   ├── cursors/types.nix    # cursorDefType, cursorsOutputType
│   ├── themes/types.nix     # themesOutputType
│   └── wallpapers/types.nix # wallpaperOutputType
└── software/
    ├── defaults/types.nix        # defaultsOutputType
    ├── launchers/types.nix       # launcherDefType, launchersOutputType
    ├── multimedia/types.nix      # mediaCommandType, multimediaOutputType
    ├── powermanagement/types.nix # powerCommandType, powermanagementOutputType
    ├── developpement/types.nix   # developpementOutputType
    └── git-accounts/types.nix   # gitAccountDefType, gitAccountsOutputType
```

`custom-config-generator.nix` imports only `configurations/types.nix`. Each domain `types.nix` imports shared primitives from `lib/types.nix` as needed. Type validation happens via `wrapPreset` which runs the preset return value through `lib.evalModules` against its declared output type at evaluation time.

---

## Home Manager Modules

Located in `homeManagerModules/`. Each module follows `default.nix → home.nix` pattern.

### Active Modules

| Module | Description |
|---|---|
| `catppuccin` | Catppuccin theme fallback |
| `hyprland` | Hyprland config (monitors, workspaces, keybinds, window rules) |
| `hyprlock` | Lock screen |
| `hypridle` | Idle management (lock@600s, screen-off@700s, suspend@900s) |
| `hyprpolkitagent` | PolicyKit agent |
| `swaync` | Notification center |
| `avizo` | Volume OSD |
| `wlogout` / `wleave` | Power/session menu |
| `ghostty` | Terminal (JetBrainsMono Nerd Font 16, stylix-themed) |
| `waybar` | Status bars (custom Nix DSL → JSON) |
| `zen-browser` | Browser (twilight-official profile, stylix-themed) |
| `brave` | Brave browser |
| `rofi` | App launcher + clipboard (cliphist) |
| `git-accounts` | Multi-account SSH + git config generation |
| `fish` | Shell (eza/bat aliases, direnv, starship) |
| `starship` | Prompt (base16 color palette, rich VCS + language segments) |
| `zellij` | Terminal multiplexer (stylix-themed) |
| `zed` | Editor (nix/toml/rust extensions, direnv, stylix-themed) |
| `jetbrains` | JetBrains IDEs (stub — `nix-jetbrains-plugins` flake ready) |

### Global Packages (selected)

**Wayland ecosystem**: hyprpaper, waybar, rofi, wleave, avizo, swaynotificationcenter
**Clipboard/Screenshot**: cliphist, wl-clipboard, grim, slurp, satty
**Audio**: easyeffects, overskride
**Editors**: neovim, helix, vscodium, zed-editor
**TUI**: yazi, zellij, gitui, btop, htop, zenith, fastfetch
**Dev tools**: ripgrep, nil, nixd, mongodb-compass, bruno, devenv, direnv
**AI tools** (unstable): ollama-rocm, opencode, claude-code, claude-monitor, spec-kit
**Communication**: slack, vesktop
**File managers**: thunar, nautilus, nemo, dolphin

---

## Desktop Environment

### Hyprland
- Source: upstream Hyprland flake (not nixpkgs)
- Launch: UWSM (Universal Wayland Session Manager) → systemd-session integrated
- All `exec-once` use `uwsm app --` prefix
- Modifier: `ALT` primary, `SUPER` secondary; vim-style H/J/K/L navigation
- 9 workspaces spread across 3 monitors by role (code / terminal / browser)

### Waybar (custom DSL)
`homeManagerModules/waybar/utils.nix` implements typed Nix constructors for each module type (`buildClockModule`, `buildWorkspaceModule`, etc.) compiled to Waybar JSON. 4 bars total:
- Top bar on each of 3 monitors
- Right-side dock on the ultrawide center monitor

Notable modules: multi-timezone clock (Europe/Paris + Africa/Algiers), workspaces, bluetooth, wireplumber, CPU/memory, privacy indicator, systemd-failed units.

### Theming
- **Stylix**: primary engine, `autoEnable = true`, drives most apps automatically
- **Catppuccin** (macchiato): fallback for apps Stylix doesn't cover
- **base16 scheme**: `catppuccin-macchiato` YAML from `base16-schemes`
- **Fonts**: Meslo Nerd Font (monospace/sans), DejaVu Serif, Noto Color Emoji
- **Cursor**: Bibata

---

## Gaming Stack

Configured in `hosts/mastodant-1/gaming.nix`:

| Category | Packages |
|---|---|
| Launchers | Steam (Proton-GE, GamescopeSession), Lutris, Bottles, Heroic, legendary-gl |
| Compatibility | Wine (staging, 32+64-bit), winetricks, protontricks |
| Performance | MangoHud, goverlay, gamemode (AMD high-perf GPU mode + renice), gamescope |
| AMD GPU | radeontop, amdgpu_top, gpu-viewer, Vulkan tools |
| Emulators | RetroArch, PCSX2, RPCS3, Dolphin, Mupen64Plus |
| Minecraft | Prism Launcher, ATLauncher |
| Controllers | xone (Xbox One/Series), xpadneo (Xbox wireless), piper, solaar (Logitech) |

---

## Secrets Management

**ragenix** (age-based secret management for Nix):
- Encrypted secrets in `secrets_store/*.age`
- Decrypted at activation using identity key `/home/karim/.ssh/id_agenix_ed25519`
- Covers SSH keys and passphrases for all 3 git accounts

---

## Flake Inputs (key)

| Input | Purpose |
|---|---|
| `nixpkgs` | `nixos-unstable` — main package set |
| `unstable-nixpkgs` | Additional bleeding-edge packages (ollama-rocm, AI tools) |
| `home-manager` | Home Manager (unstable) |
| `hyprland` | Hyprland compositor (upstream flake) |
| `stylix` | Theming engine |
| `catppuccin` | Catppuccin HM module |
| `ragenix` | Secret management |
| `darwin` + `nixpkgs-darwin` | Darwin (scaffolded, not active) |
| `nix-jetbrains-plugins` | JetBrains IDE plugins (ready, not yet wired) |
| `base16-schemes` | Color scheme YAML files |

---

## Development Notes

- `TODO.md` exists at project root with active development tasks
- `hyprland-windowsrules.md` documents window rule syntax
- `git-scripts-accounts.md` documents multi-account git workflow
- Branch `feature/add-zed-editor` is currently active (Zed editor integration)
- JetBrains module is a stub (`home.nix` is empty) despite the flake input being present

---

## Potential Areas for Improvement / TODOs

- **Darwin support**: Full scaffold exists but is commented out; enabling it would be straightforward
- **JetBrains**: Flake input present, module stub exists — needs wiring
- **`nixosModules/` and `nixDarwinModules/`**: Both empty stubs
- **Multi-host**: Preset system is designed for multi-machine use but only one host exists
