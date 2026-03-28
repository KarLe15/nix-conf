# brave

Configures the Brave browser.

## What it does

Installs Brave browser. Check `home.nix` for the current configuration state.

## customConfigs dependencies

None.

## Notes

- Brave is declared as a package in the global list in `homeManagerModules/default.nix`
- Window rules for Brave popups are defined in the `hyprland` module (`match:class brave` → float + center + max_size)
