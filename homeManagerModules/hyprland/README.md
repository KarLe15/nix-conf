# hyprland

Configures the Hyprland Wayland compositor via `wayland.windowManager.hyprland`.

## What it does

- Declares monitor layout from the active monitors preset
- Creates workspace-to-monitor assignments and keyboard shortcuts
- Builds keybindings from the shortcuts preset, injecting UWSM app wrapping for all `exec` dispatchers
- Configures mouse binds (ALT+LMB = move, ALT+RMB = resize)
- Declares window rules for satty, GTK file dialogs, Brave popups, and VSCodium dialogs
- Builds the `exec-once` autostart list by merging autostart from defaults, launchers, developpement, themes, and cursors presets

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `hardwareConfigs.monitors` | `.apply { inherit pkgs; }` → monitor definitions and disposition |
| `styleConfigs.workspaces` | `.apply { monitors; pkgs; }` → workspace list and navigation |
| `styleConfigs.cursors` | `.apply { inherit pkgs; }` → cursor name and size |
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → default programs (autostart) |
| `softwareConfigs.launchers` | `.apply { inherit pkgs; }` → launcher autostart |
| `softwareConfigs.developpement` | `.apply { inherit pkgs; }` → dev tool autostart |
| `softwareConfigs.multimedia` | `.apply { inherit pkgs; }` → multimedia commands for shortcuts |
| `softwareConfigs.shortcuts` | `.shortcuts-definition { defaults; developpement; launchers; multimedia; pkgs; }` |

## Shortcut structure

Each shortcut in the shortcuts preset is an attrset:

```nix
{
  description  = string;
  mod1         = string;   # e.g. "ALT", "SUPER", ""
  key          = string;   # e.g. "T", "XF86AudioRaiseVolume"
  dispatcher-type = string; # e.g. "exec", "killactive", "fullscreen"
  command      = string;
  env          = string;   # optional env var prefix for exec dispatchers
}
```

## Notes

- `systemd.enable = false` — Hyprland session integration is handled by UWSM, not the built-in systemd target
- All `exec` dispatchers are wrapped with `uwsm app --` for proper systemd session tracking
- The `mapDirectionToHyprland` helper converts cardinal directions (Left/Right/Up/Down) to Hyprland focus codes
