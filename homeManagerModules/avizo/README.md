# avizo

Configures Avizo as the on-screen display (OSD) for volume and brightness changes.

## What it does

- Enables Avizo as a Home Manager service (`services.avizo`)
- Delegates theming to Stylix (`stylix.targets.avizo.enable = true`)
- Sets OSD display timing: 1s visible, 0.1s fade-in, 0.2s fade-out, vertically centered

## OSD settings

| Setting | Value |
|---|---|
| `time` | 1.0 s |
| `y-offset` | 0.5 (vertically centred) |
| `fade-in` | 0.1 s |
| `fade-out` | 0.2 s |
| `padding` | 10 px |

## customConfigs dependencies

None — Avizo itself has no preset dependency. The `volumectl` commands that trigger Avizo are defined in `configurations/software/multimedia/presets/avizo.nix` and injected via the shortcuts preset.

## Notes

- Volume control commands use `volumectl -M 0 -d -u up/down/toggle-mute` (from the avizo multimedia preset)
- These commands are bound to `XF86AudioRaiseVolume`, `XF86AudioLowerVolume`, and `XF86AudioPlay` in the shortcuts preset
