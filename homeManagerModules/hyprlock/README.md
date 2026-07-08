# hyprlock

Configures Hyprlock as the Wayland lock screen.

## What it does

- Enables Hyprlock via `programs.hyprlock`
- Delegates theming to Stylix (`stylix.targets.hyprlock.enable = true`)
- Explicitly disables the Stylix wallpaper on the lock screen (`useWallpaper = false`)

## customConfigs dependencies

None.

## Notes

- The `settings` block is empty — lock screen layout uses Stylix defaults
- Hyprlock is launched via `loginctl lock-session` triggered by Hypridle at 600s idle
- `hyprlock` package is also declared in the global package list in `homeManagerModules/default.nix`
