# Home Manager Modules

All user-level configuration lives here. Every module follows this layout:

```
<module>/
├── default.nix   # { imports = [ ./home.nix ]; }
└── home.nix      # Actual Home Manager configuration
```

Modules receive `customConfigs` (a resolved preset data set) as a `specialArg`.
They do **not** declare NixOS options for preset selection — that is handled by
`configurations/` and `custom-config-generator.nix`.

---

## Module Index

| Module | Status | Description |
|---|---|---|
| [`hyprland`](hyprland/) | active | Wayland compositor — monitors, workspaces, keybindings, window rules |
| [`waybar`](waybar/) | active | Status bars via a custom Nix DSL |
| [`ghostty`](ghostty/) | active | Terminal emulator |
| [`fish`](fish/) | active | Shell — aliases, direnv, starship init |
| [`starship`](starship/) | active | Shell prompt |
| [`zed`](zed/) | active | Zed editor |
| [`zellij`](zellij/) | active | Terminal multiplexer |
| [`git-accounts`](git-accounts/) | active | Multi-account SSH + git configuration |
| [`rofi`](rofi/) | active | App launcher + clipboard manager |
| [`swaync`](swaync/) | active | Notification center |
| [`avizo`](avizo/) | active | Volume / brightness OSD |
| [`wleave`](wleave/) | active | Power / session menu |
| [`hyprlock`](hyprlock/) | active | Lock screen |
| [`hypridle`](hypridle/) | active | Idle management |
| [`hyprpolkitagent`](hyprpolkitagent/) | active | PolicyKit agent |
| [`zen-browser`](zen-browser/) | active | Zen browser |
| [`brave`](brave/) | active | Brave browser |
| [`catppuccin`](catppuccin/) | active | Catppuccin theming fallback |
| [`jetbrains`](jetbrains/) | stub | JetBrains IDEs — flake input ready, not yet wired |
| [`wlogout`](wlogout/) | inactive | Legacy power menu (replaced by wleave) |
| [`eww`](eww/) | disabled | Widget system — imported but disabled |

---

## `default.nix` (root module)

The root module imports every sub-module and declares global packages and global stylix settings.

**Global stylix settings:**
- `stylix.autoEnable = true` — applies Stylix theming to all supported apps automatically
- GTK extra CSS — strips box-shadows and client-side decorations from dialogs/filechoosers

**Global packages** are split into two lists:
- `stablePackages` — from main `nixpkgs` (unstable channel)
- `unstablePackages` — from a second `unstable-nixpkgs` instantiation for bleeding-edge tools

Notable packages: hyprland ecosystem, clipboard tools, screenshot tools, TUI tools, editors,
AI tooling (ollama-rocm, opencode, claude-code, claude-monitor, spec-kit).

---

## customConfigs Reference

Modules access preset data through `customConfigs`:

```
customConfigs
├── hardwareConfigs
│   └── monitors          ← hardware/monitors preset (call .apply { inherit pkgs; })
├── styleConfigs
│   ├── workspaces        ← style/workspaces preset
│   ├── status-bars       ← style/status-bars preset
│   ├── themes            ← style/themes preset
│   ├── cursors           ← style/cursors preset
│   ├── fonts             ← style/fonts preset
│   └── wallpaper         ← style/wallpapers preset
└── softwareConfigs
    ├── defaults          ← software/defaults preset (browser, terminal, editor, etc.)
    ├── shortcuts         ← software/shortcuts preset
    ├── launchers         ← software/launchers preset
    ├── powermanagement   ← software/powermanagement preset
    ├── multimedia        ← software/multimedia preset
    ├── git-accounts      ← software/git-accounts preset
    ├── developpement     ← software/developpement preset
    └── modules           ← feature flags (attrset of { enable = bool; })
        ├── eww.enable
        ├── walker.enable
        ├── git-accounts.enable
        └── waybar.enable
```

Every preset value is an attrset with an `apply` function. Call it to get the resolved data:

```nix
let
  monitors = customConfigs.hardwareConfigs.monitors.apply { inherit pkgs; };
  defaults = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
in ...
```
