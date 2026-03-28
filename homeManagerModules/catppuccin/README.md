# catppuccin

Sets the Catppuccin theme flavor for apps that support the Catppuccin Home Manager module.

## What it does

- Sets `catppuccin.flavor = "macchiato"` globally
- This is a fallback theming layer for applications not covered by Stylix

## customConfigs dependencies

Reads `customConfigs.styleConfigs.cursors` (calls `.apply { inherit pkgs; }`) — cursor data is imported but not currently used in this module.

## Theming hierarchy

```
Stylix (primary, autoEnable = true)
  └── covers most apps automatically
Catppuccin HM module (fallback)
  └── covers apps with native Catppuccin support but no Stylix target
```

## Notes

- The active flavor (`macchiato`) is hardcoded in this module. If you change the theme preset, update this value as well — ideally this should be derived from `customConfigs.styleConfigs.themes`
- Catppuccin wleave is explicitly disabled in the `wleave` module
