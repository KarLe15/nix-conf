# swaync

Configures SwayNotificationCenter as the Wayland notification daemon.

## What it does

- Enables swaync as a Home Manager service (`services.swaync`)
- Delegates theming to Stylix (`stylix.targets.swaync.enable = true`)

## customConfigs dependencies

None.

## Notes

- The `style` field and `settings` attrset are currently empty — swaync runs with Stylix defaults
- The notification center is opened via the shortcut `ALT_SHIFT + N` (defined in the shortcuts preset), which calls `swaync-client -t`
- `swaynotificationcenter` package is also in the global package list in `homeManagerModules/default.nix`
