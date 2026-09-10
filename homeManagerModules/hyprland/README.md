# hyprland

Configures the Hyprland Wayland compositor via `wayland.windowManager.hyprland`.

Since Hyprland 0.55 the compositor is configured in **Lua**, not hyprlang. This
module sets `configType = "lua"` explicitly and generates
`~/.config/hypr/hyprland.lua`. See
[docs/HYPRLAND-LUA-MIGRATION.md](../../docs/HYPRLAND-LUA-MIGRATION.md) for the
migration record and the remaining refactor plan.

## What it does

- Declares monitor layout from the active monitors preset (`hl.monitor`)
- Creates workspace-to-monitor assignments (`hl.workspace_rule`) and their keybindings
- Builds keybindings from the shortcuts preset, injecting UWSM app wrapping for all
  `exec` dispatchers, and attaching each shortcut's `description` to the bind
- Adds mouse binds (ALT+LMB = move, ALT+RMB = resize) as ordinary binds carrying
  the `mouse` option
- Declares window rules for satty, GTK file dialogs, Brave popups, and VSCodium
  dialogs (`hl.window_rule`, with typed `match` tables)
- Runs the merged autostart list (defaults, launchers, developpement, themes,
  cursors) from a `hyprland.start` event handler

## How the Lua config is generated

Home Manager's Lua renderer maps **each top-level `settings` key to a literal
`hl.<key>(...)` call**:

```nix
renderCall = name: value: "hl.${name}(${renderLuaArgs value})\n";
```

So every key in `settings` must be a real function of the `hl` API — not a hyprlang
section name. Getting this wrong does not fail the build: the compositor rejects the
file at login and silently falls back to its defaults.

| `settings` key | Renders as | Notes |
|---|---|---|
| `config` | `hl.config({ … })` | Holds what used to be hyprlang sections (`general`, `input`, …). Stylix merges its palette into this same key |
| `monitor` | `hl.monitor({ output, mode, position, scale })` | One call per list element |
| `bind` | `hl.bind(keys, <dispatcher>, <opts>)` | Built with `_args`; the dispatcher is raw Lua via `mkLuaInline` |
| `window_rule` | `hl.window_rule({ name, match = { class, title }, … })` | Named rules |
| `workspace_rule` | `hl.workspace_rule({ workspace, monitor, … })` | |
| `on` | `hl.on("hyprland.start", function() … end)` | Startup commands — **there is no `hl.exec_once`** |

Two helper conventions in `home.nix`:

- `keyCombo` rewrites hyprlang's `ALT_SHIFT` into the Lua bind API's `ALT+SHIFT`.
- `mkDispatcher` maps a shortcut preset entry's `dispatcher-type` to its `hl.dsp.*`
  equivalent, and throws at evaluation time for an unmapped dispatcher.

### Field types that bite

These are not checkable offline — they surface only when the compositor loads the
file:

| Field | Required form |
|---|---|
| `general.gaps_out` | `css_gap`: an integer, or `{ top, right, bottom, left }` — **not** the hyprlang `"10,3,5,3"` string |
| `window_rule.max_size` | `vec2`: exactly two positional elements, `[ 1084 653 ]` → `{ 1084, 653 }` |
| `window.fullscreen` mode | `"fullscreen"` or `"maximized"` (not `"maximize"`) |

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `hardwareConfigs.monitors` | `.apply { inherit pkgs; }` → monitor definitions and disposition |
| `styleConfigs.workspaces` | `.apply { monitors; pkgs; }` → workspace list and navigation |
| `styleConfigs.cursors` | `.apply { inherit pkgs; }` → cursor name and size |
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → default programs (autostart) |
| `softwareConfigs.launchers` | `.apply { inherit pkgs; }` → launcher autostart |
| `softwareConfigs.developpement` | `.apply { inherit pkgs; }` → dev tool autostart |
| `softwareConfigs.multimedia` | `.apply { inherit pkgs; }` → multimedia commands for shortcuts |
| `softwareConfigs.shortcuts` | `.shortcuts-definition { defaults; developpement; launchers; multimedia; pkgs; }` |

## Shortcut structure

Each shortcut in the shortcuts preset is an attrset:

```nix
{
  description  = string;
  mod1         = string;   # e.g. "ALT", "SUPER", "" — "_" becomes "+" for Lua
  key          = string;   # e.g. "T", "XF86AudioRaiseVolume", "mouse:277"
  dispatcher-type = string; # mapped to hl.dsp.* by mkDispatcher
  command      = string;   # argument to the dispatcher
  env          = string;   # optional env var prefix for exec dispatchers
}
```

Supported `dispatcher-type` values and their Lua equivalents:

| `dispatcher-type` | Lua |
|---|---|
| `exec` | `hl.dsp.exec_cmd(…)` (uwsm-wrapped) |
| `killactive` | `hl.dsp.window.close()` |
| `forcekillactive` | `hl.dsp.window.kill()` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `fullscreen` | `hl.dsp.window.fullscreen({ mode = "fullscreen" \| "maximized", action = "toggle" })` |
| `togglespecialworkspace` | `hl.dsp.workspace.toggle_special()` |
| `movetoworkspacesilent` | `hl.dsp.window.move({ workspace = …, silent = true })` |

Anything else throws at evaluation time.

> Widening this schema (`mods` list, bind `flags`, `submap`) is Phase 2 of the
> migration plan. The shortcuts preset has a single consumer — this module — so the
> change cannot affect Waybar or Quickshell.

## Notes

- `systemd.enable = false` — Hyprland session integration is handled by UWSM, not the
  built-in systemd target
- All `exec` dispatchers are wrapped with `uwsm app --` for proper systemd session
  tracking
- Lua and hyprlang configs are mutually exclusive per session: switching needs a full
  logout/login, not `hyprctl reload`
- The window rules and `general` / `input` sections are still hardcoded here rather
  than in a `configurations/` preset — Phase 1 of the migration plan moves them
