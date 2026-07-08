# hypridle

Configures Hypridle for idle-based power management.

## What it does

- Enables Hypridle as a Home Manager service (`services.hypridle`)
- Builds lock and suspend commands from the defaults and powermanagement presets

## Idle timeouts

| Timeout | Action |
|---|---|
| 600 s | Lock session (`loginctl lock-session`) |
| 700 s | Turn off all displays (`hyprctl dispatch dpms off`) |
| 900 s | Suspend system (`systemctl suspend`) |

On resume from display-off: `hyprctl dispatch dpms on` restores the screens.

The lock command uses `pidof <locker> || <locker>` to avoid spawning duplicate lock screen instances.

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → `lockscreen.command` |
| `softwareConfigs.powermanagement` | `.apply { inherit pkgs; }` → `commands.suspend.command` |
