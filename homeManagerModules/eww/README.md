# eww

**Status: disabled.**

Placeholder for [Eww](https://github.com/elkowar/eww) widget system configuration.

## Current state

The module is imported in `homeManagerModules/default.nix` but the feature flag
`softwareConfigs.modules.eww.enable = false` disables it in `custom-config-generator.nix`.

The `eww` package is commented out in the global package list.

## To enable

1. Set `modules.eww.enable = true` in `custom-config-generator.nix`
2. Uncomment `eww` in the global package list in `homeManagerModules/default.nix`
3. Add Eww widget definitions and windows to `home.nix`
