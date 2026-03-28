# hyprpolkitagent

Enables the Hyprland PolicyKit authentication agent.

## What it does

Enables `services.hyprpolkitagent` so that GUI applications requesting elevated privileges
(e.g., package managers, disk tools) receive a graphical authentication prompt.

## customConfigs dependencies

None.

## Notes

- No additional configuration is needed; the agent integrates automatically with Hyprland's systemd session via UWSM
