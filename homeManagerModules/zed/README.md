# zed

Configures the Zed editor.

## What it does

- Enables Zed via `programs.zed-editor`
- Installs extensions: `nix`, `toml`, `rust`, `material-icon-theme`
- Delegates theming to Stylix (`stylix.targets.zed.enable = true`)

## Settings applied

| Setting | Value | Reason |
|---|---|---|
| `auto_update` | `false` | Managed by Nix |
| `format_on_save` | `"off"` | Explicit save discipline preferred |
| `show_whitespaces` | `"trailing"` | Highlight trailing whitespace |
| `vim_mode` | `false` | Modal editing not used |
| `load_direnv` | `"shell_hook"` | Load `.envrc` via shell hook for proper env vars |
| `hour_format` | `"hour24"` | 24h time in UI |
| `ui_font_size` | `20.0` | Default UI font size (can be overridden per machine with `lib.mkForce`) |

## customConfigs dependencies

None.

## Notes

- `nil` and `nixd` (Nix language servers) are declared in the global package list in `homeManagerModules/default.nix`
- `zed-editor` package is also in the global package list
- Stylix handles background, syntax colors, and UI theme automatically
