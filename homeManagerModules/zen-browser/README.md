# zen-browser

Configures the Zen browser (Firefox-based, privacy-focused).

## What it does

- Enables Zen browser via `programs.zen-browser`
- Delegates theming to Stylix (`stylix.targets.zen-browser.enable = true`) targeting the `"Default Profile"` profile

## customConfigs dependencies

None.

## Notes

- Zen browser is provided by the `zen-browser` flake input (not from nixpkgs)
- The profile name `"Default Profile"` must match the actual profile directory name on disk; adjust if your profile has a different name
- Zen browser is not set as the default browser in the defaults preset (`mastodant-1`) — Firefox is the configured default
