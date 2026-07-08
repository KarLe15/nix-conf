# waybar

Configures Waybar status bars using a **custom Nix DSL** defined in `utils.nix`.

## What it does

- Conditionally enabled via `customConfigs.softwareConfigs.modules.waybar.enable`
- Resolves the active status-bar preset to get bar layout and style
- Passes each bar definition through `utils.nix:buildBarObject` to compile it into Waybar JSON
- Runs as a systemd service (`waybar.systemd.enable = true`)
- Stylix theming is explicitly **disabled** (`stylix.targets.waybar.enable = false`) — styling comes from the status-bars preset CSS file

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `hardwareConfigs.monitors` | `.apply { inherit pkgs; }` → screen names for bar output assignment |
| `styleConfigs.workspaces` | `.apply { inherit pkgs monitors; }` → workspace list for the workspaces module |
| `styleConfigs.status-bars` | `.apply { workspaces; default-programs; multimedia-programs; pkgs; }` → bar definitions + style CSS |
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → default programs for custom launcher modules |
| `softwareConfigs.multimedia` | `.apply { inherit pkgs; }` → volume commands for wireplumber module |
| `softwareConfigs.modules.waybar.enable` | boolean feature flag |

## utils.nix — Waybar DSL

`utils.nix` exports a single function `buildBarObject` that converts a declarative bar config into a Waybar JSON-compatible attrset.

### Bar config shape

```nix
{
  name            = string;
  position        = "top" | "bottom" | "left" | "right";
  screen          = string;      # output name, e.g. "HDMI-A-2"
  spacing         = int;
  modules_left    = [ module ];
  modules_center  = [ module ];
  modules_right   = [ module ];
}
```

### Module shape

```nix
{
  type   = string;   # see supported types below
  id     = string;   # Waybar module ID, e.g. "hyprland/workspaces"
  config = attrset;  # type-specific config (see builder functions)
}
```

### Supported module types

| Type | Builder | Config fields |
|---|---|---|
| `workspaces` | `buildWorkspaceModule` | `workspaces: [{ id, icon }]` |
| `clock` | `buildClockModule` | `all_timezones`, `default_timezone` |
| `bluetooth` | `buildBluetoothModule` | `on-click-middle` |
| `cpu` | `buildCpuModule` | _(no config fields)_ |
| `memory` | `buildMemoryModule` | _(no config fields)_ |
| `network` | `buildNetworkModule` | `display: "vertical" \| "standard" \| "bandwidth"` |
| `privacy` | `buildPrivacyModule` | _(no config fields)_ |
| `user` | `buildUserModule` | `avatar_path`, `size` |
| `wireplumber` | `buildWireplumberModule` | `toggle_mute_volume_command`, `default_sound_manager_command`, `increase_volume_command`, `lower_volume_command` |
| `image` | `buildImageModule` | `path`, `size` |
| `systemd-failed-display` | `buildSystemdUnitStatusModule` | _(no config fields)_ |
| `custom` | `buildCustomModule` | `format`, `on_click_command` |
| `group` | `buildGroupModule` | `orientation`, `transition_duration`, `transition_left_to_right`, `click_to_reveal`, `sub_modules: [module]` |

Groups (`group`) support nested `sub_modules`, which are recursively extracted and added to the Waybar config via `get_sub_modules_from_drawer`.
