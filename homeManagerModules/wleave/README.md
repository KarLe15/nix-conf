# wleave

Configures WLeave as the power/session menu.

## What it does

- Enables WLeave via `programs.wleave`
- Builds button list from the powermanagement preset (shutdown/reboot/suspend/hibernate) and defaults preset (lock screen)
- Sets a 200px margin, 2-3 buttons per row, keyboard shortcuts, and closes on focus loss

## Buttons

| Label | Key | Action source |
|---|---|---|
| Shutdown | `s` | `powermanagement.commands.shutdown.command` |
| Reboot | `r` | `powermanagement.commands.reboot.command` |
| Quick Lock | `l` | `defaults.lockscreen.command` |
| Lock Power Down | `p` | `powermanagement.commands.suspend.command` |
| Hibernate | `h` | `powermanagement.commands.hibernate.command` |

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → `lockscreen.command` |
| `softwareConfigs.powermanagement` | `.apply { inherit pkgs; }` → shutdown/reboot/suspend/hibernate commands |

## Notes

- WLeave is launched with `wleave -kf` (defined in the defaults preset)
- The `GDK_PIXBUF_MODULE_FILE` env var is set in the logout shortcut to fix SVG icon loading (known issue with librsvg)
- Catppuccin theming is explicitly disabled (`catppuccin.wleave.enable = false`) — theming relies on Stylix instead
- `wlogout` module is kept for reference but WLeave is the active implementation
