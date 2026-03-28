# rofi

Configures the Rofi app launcher.

## What it does

- Enables Rofi via `programs.rofi`
- Writes `~/.config/rofi/theme.rasi` from the bundled `theme.rasi` file
- Delegates color theming to Stylix (`stylix.targets.rofi.enable = true`)

## customConfigs dependencies

None directly — launcher commands are defined in the `software/launchers` preset and consumed by the `hyprland` module for keybinding injection.

## Notes

- The `theme.rasi` path is currently hardcoded in `configurations/software/launchers/presets/rofi.nix` as an absolute path (`/home/karim/.config/rofi/theme.rasi`) — this is a known TODO
- Clipboard integration uses `cliphist` piped through Rofi dmenu; `cliphist store` watchers are declared in the launchers preset autostart list
- `rofi` package is also declared in the global package list in `homeManagerModules/default.nix`
