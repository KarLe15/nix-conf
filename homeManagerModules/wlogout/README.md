# wlogout

**Status: inactive (replaced by wleave).**

Legacy power/session menu using WLogout. Kept for reference.

## Current state

`programs.wlogout.enable = false` — the module is imported but wlogout is disabled.
WLeave (`wleave` module) is the active implementation.

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → `lockscreen.command` |
| `softwareConfigs.powermanagement` | `.apply { inherit pkgs; }` → shutdown/reboot/suspend/hibernate commands |

## Notes

- Catppuccin theming for wlogout is explicitly disabled
- If switching back to wlogout, note that wleave and wlogout use different JSON structures for buttons
