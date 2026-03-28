# ghostty

Configures the Ghostty terminal emulator.

## What it does

- Enables Ghostty via `programs.ghostty`
- Overrides font to JetBrainsMono Nerd Font at size 16
- Delegates all theming (colors, background, etc.) to Stylix (`stylix.targets.ghostty.enable = true`)

## customConfigs dependencies

None.

## Notes

- Font family is forced with `lib.mkForce` to override any Stylix font injection for the terminal
- Font size is similarly forced — change `16` here if you want a different terminal font size
- Ligatures are noted as non-functional with MesloLG fonts (see TODO in `home.nix`)
- Ghostty package is also declared in the global package list in `homeManagerModules/default.nix`
