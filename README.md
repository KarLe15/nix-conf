# NixOS Configuration

Personal NixOS + Home Manager configuration for an AMD gaming/development desktop (`mastodant1`, hostname `karle`).

**Version**: 0.1.0 — **Date**: 2026-03-19

---

## Quick Overview

| Property | Value |
|---|---|
| Architecture | `x86_64-linux` |
| User | `karim` |
| Desktop | Hyprland (via UWSM + SDDM) |
| Shell | Fish + Starship |
| Terminal | Ghostty |
| Theming | Stylix (primary) + Catppuccin macchiato (fallback) |
| Secrets | ragenix (age-encrypted) |

---

## Directory Structure

```
config/
├── flake.nix                      # Flake entrypoint — defines nixosConfigurations outputs
├── flake.lock                     # Pinned input versions
├── custom-config-generator.nix    # Preset resolver: maps preset names → Nix data
│
├── hosts/                         # Per-machine NixOS system-level config
│   └── mastodant-1/               # AMD desktop
│       ├── configuration.nix      # Top-level imports
│       ├── options.nix            # Preset selections for this machine ← start here
│       ├── kernel.nix             # AMD GPU, power params, gaming sysctl
│       ├── hardware-configuration.nix
│       ├── custom-hardware.nix
│       ├── services-configuration.nix  # SDDM, PipeWire, printing
│       ├── networks.nix           # Hostname, NetworkManager
│       ├── locales.nix            # TZ, keyboard, locale
│       ├── security.nix           # rtkit, PAM
│       ├── users.nix              # User definition
│       ├── programs.nix           # Firefox, Hyprland, fish
│       ├── gaming.nix             # Full gaming stack
│       ├── developpement.nix      # Docker, Podman
│       └── filesystems.nix        # Storage layout
│
├── homeManagerModules/            # Home Manager module library
│   ├── default.nix                # Root: imports all modules + global packages
│   ├── hyprland/                  # Wayland compositor
│   ├── waybar/                    # Status bars (custom Nix DSL)
│   ├── fish/                      # Shell
│   ├── starship/                  # Prompt
│   ├── ghostty/                   # Terminal
│   ├── zed/                       # Editor
│   ├── zellij/                    # Terminal multiplexer
│   ├── git-accounts/              # Multi-account SSH + git config
│   ├── rofi/                      # App launcher
│   ├── swaync/                    # Notification center
│   ├── avizo/                     # Volume OSD
│   ├── wleave/                    # Power menu
│   ├── hyprlock/                  # Lock screen
│   ├── hypridle/                  # Idle manager
│   ├── hyprpolkitagent/           # PolicyKit agent
│   ├── zen-browser/               # Zen browser
│   ├── brave/                     # Brave browser
│   ├── catppuccin/                # Catppuccin theme fallback
│   └── jetbrains/                 # JetBrains IDEs (stub)
│
├── configurations/                # Pure-data preset library
│   ├── hardware/monitors/         # Monitor layouts
│   ├── style/                     # themes, fonts, cursors, wallpapers, workspaces, status-bars
│   └── software/                  # defaults, shortcuts, git-accounts, launchers, multimedia, powermanagement, developpement
│
├── nixCommonModules/              # Shared NixOS + Darwin modules (cursor, stylix, secrets)
├── nixosModules/                  # NixOS-only modules (stubs)
├── nixDarwinModules/              # Darwin-only modules (stubs)
├── secrets_store/                 # ragenix-encrypted .age secret files
├── local_secrets/                 # Local (untracked) secrets
└── docs/                          # Design documents and proposals
```

---

## The Preset System

This is the central architectural pattern. Rather than hardcoding values in modules, each host
declares *which named preset* to use for each configuration domain:

```nix
# hosts/mastodant-1/options.nix
hardware.monitors.active    = "mastodant-3-screens";
style.themes.active         = "catppuccin-macchiato";
style.fonts.active          = "mac-like";
style.cursors.active        = "Bibata";
style.wallpaper.active      = "standard";
style.workspaces.active     = "standard-3-screen";
style.statusbar.active      = "waybar-3-screen";
software.defaults.active    = "mastodant-1";
software.shortcuts.active   = "mastodant-1";
software.git-accounts.active = "standard";
software.launchers.active   = "rofi";
software.powermanagement.active = "systemD";
software.multimedia.active  = "avizo";
software.developpement.active = "opensource";
```

`custom-config-generator.nix` resolves these strings to Nix attribute sets by importing the
matching preset file. The resolved `customConfigs` value is injected as a `specialArg` into all
Home Manager modules, which consume it as `customConfigs.hardwareConfigs`, `customConfigs.styleConfigs`,
and `customConfigs.softwareConfigs`.

### Adding a New Preset

1. Create `configurations/<domain>/presets/<name>.nix` exporting `{ apply = {...}: {...}; autostart = []; }`
2. Change the `active` option in `hosts/<machine>/options.nix` to `"<name>"`

### Adding a New Domain

1. Create `configurations/<domain>/default.nix` declaring a NixOS option `<domain>.<name>.active`
2. Create `configurations/<domain>/types.nix` defining the output type for this domain (import shared primitives from `configurations/lib/types.nix` as needed)
3. Add the import of the new `types.nix` to `configurations/types.nix` (the flat aggregator)
4. Add an import to `configurations/default.nix`
5. Add a `wrapPreset` resolution in `custom-config-generator.nix`

---

## Home Manager Modules

See [`homeManagerModules/README.md`](homeManagerModules/README.md) for an overview of all modules.

Each module lives in its own subdirectory under `homeManagerModules/` and follows this layout:

```
<module>/
├── default.nix   # Thin wrapper: { imports = [ ./home.nix ]; }
└── home.nix      # Actual Home Manager configuration
```

Modules consume `customConfigs` (injected via `specialArg`) to read preset data.

---

## Secrets

Secrets are managed with [ragenix](https://github.com/yaxitech/ragenix):
- Encrypted secrets live in `secrets_store/*.age`
- Decrypted at activation using the identity key at `/home/karim/.ssh/id_agenix_ed25519`
- Covers: SSH private keys and passphrases for all git accounts

---

## Flake Inputs

| Input | Source | Purpose |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Main package set |
| `unstable-nixpkgs` | `nixos-unstable` (second instance) | Bleeding-edge packages (AI tools, ollama) |
| `home-manager` | upstream unstable | Home Manager |
| `hyprland` | upstream flake | Hyprland compositor |
| `stylix` | upstream | Theming engine |
| `catppuccin` | upstream | Catppuccin HM module |
| `ragenix` | upstream | Secret management |
| `base16utils` | SenchoPens/base16.nix | base16 scheme → Nix conversion |
| `darwin` + `nixpkgs-darwin` | lnl7/nix-darwin | Darwin support (scaffolded, not active) |
| `nix-jetbrains-plugins` | theCapypara | JetBrains IDE plugins (ready, not wired) |
| `zen-browser` | 0xc000022070 | Zen browser flake |

---

## Adding a New Host

1. Copy `hosts/mastodant-1/` to `hosts/<hostname>/`
2. Run `nixos-generate-config` on the new machine and replace `hardware-configuration.nix`
3. Edit `options.nix` to select appropriate presets (or create new ones)
4. Add a `nixosConfigurations.<hostname>` entry to `flake.nix` following the `mkNixosSystem` pattern

---

## See Also

- [`SUMMARY.md`](SUMMARY.md) — Full project analysis
- [`docs/ENHANCEMENT-PROFILES.md`](docs/ENHANCEMENT-PROFILES.md) — Proposed profile/feature system
- [`docs/QUICKSHELL-SHELL.md`](docs/QUICKSHELL-SHELL.md) — Quickshell desktop shell plan & progress
- [`homeManagerModules/README.md`](homeManagerModules/README.md) — Module index
- [`TODO.md`](TODO.md) — Active development notes
