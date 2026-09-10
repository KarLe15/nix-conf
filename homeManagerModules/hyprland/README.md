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

Nix emits **data only**. `home.nix` serialises the presets into a generated
`data.lua`, and the checked-in `lua/*.lua` turn that data into `hl.*` calls — the
same split as the Quickshell `Config.qml` / QML-widget arrangement.

```
homeManagerModules/hyprland/
├── home.nix          # presets -> data.lua (+ the settings keys below)
└── lua/
    ├── binds.lua     # bind records -> hl.bind() / hl.define_submap()
    └── startup.lua   # hyprland.start handler
```

No Lua source is built by string concatenation: `data.lua` goes through
`lib.generators.toLua`. The whole `hl` API surface lives in `lua/binds.lua`, where
an unknown dispatcher raises a Lua error naming the bind.

What still goes through `settings` — Home Manager renders **each top-level key as a
literal `hl.<key>(...)` call**:

```nix
renderCall = name: value: "hl.${name}(${renderLuaArgs value})\n";
```

So every key in `settings` must be a real function of the `hl` API — not a hyprlang
section name. Getting this wrong does not fail the build: the compositor rejects the
file at login and silently falls back to its defaults.

| `settings` key | Renders as | Notes |
|---|---|---|
| `config` | `hl.config({ … })` | Host preset `sections`. Stylix merges its palette into this same key, which is why it stays here rather than moving to `data.lua` |
| `monitor` | `hl.monitor({ output, mode, position, scale })` | One call per list element |
| `window_rule` | `hl.window_rule({ name, match = { class, title }, … })` | Host preset `window-rules` |
| `workspace_rule` | `hl.workspace_rule({ workspace, monitor, … })` | Workspaces preset, plus the host preset's `workspace-rules` |

Binds and startup commands are **not** in `settings` — they go through `data.lua`
and `lua/binds.lua` / `lua/startup.lua`.

Conventions in `home.nix`:

- `keyCombo` joins the preset's `mods` list into the Lua bind API's `ALT+SHIFT+F`.
- `splitMods` normalises the *workspaces* preset, which is shared with waybar and
  quickshell and still spells modifiers `"ALT_SHIFT"`.
- `shortcutData` normalises an entry's `args` so `lua/binds.lua` never supplies a
  default — `follow` in particular is always emitted, since its absence caused a
  regression once already.

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
| `styleConfigs.hyprland` | `.apply { inherit pkgs; }` → `sections`, `window-rules`, `workspace-rules` |
| `hardwareConfigs.monitors` | `.apply { inherit pkgs; }` → monitor definitions and disposition |
| `styleConfigs.workspaces` | `.apply { monitors; pkgs; }` → workspace list and navigation |
| `styleConfigs.cursors` | `.apply { inherit pkgs; }` → cursor name and size |
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → default programs (autostart) |
| `softwareConfigs.launchers` | `.apply { inherit pkgs; }` → launcher autostart |
| `softwareConfigs.developpement` | `.apply { inherit pkgs; }` → dev tool autostart |
| `softwareConfigs.multimedia` | `.apply { inherit pkgs; }` → multimedia commands for shortcuts |
| `softwareConfigs.shortcuts` | `.shortcuts-definition { defaults; developpement; launchers; multimedia; pkgs; }` |

## Shortcut structure

Each shortcut in the shortcuts preset is an attrset. Everything but
`description`, `key` and `dispatcher` has a default, so an entry states only what
it needs:

```nix
{
  description = string;      # attached to the bind, queryable at runtime
  mods        = [ string ];  # [ ] for none; joined with "+"
  key         = string;      # "T", "XF86AudioRaiseVolume", "mouse:277"
  dispatcher  = string;      # see the table below
  args        = attrs;       # dispatcher arguments, named per dispatcher
  flags       = attrs;       # locked / repeating / release / long_press / mouse
  submap      = string|null; # null = always active
  env         = string;      # environment prefix for `exec`
}
```

`home.nix` turns these into records in `data.lua`; `lua/binds.lua` maps the
`dispatcher` name onto the API:

| `dispatcher` | `args` | Lua |
|---|---|---|
| `exec` | `{ cmd }` | `hl.dsp.exec_cmd(…)` (uwsm-wrapped) |
| `killactive` | — | `hl.dsp.window.close()` |
| `forcekillactive` | — | `hl.dsp.window.kill()` |
| `togglefloating` | — | `hl.dsp.window.float({ action = "toggle" })` |
| `fullscreen` | `{ mode }` | `hl.dsp.window.fullscreen({ mode, action = "toggle" })` — `"fullscreen"` or `"maximized"` |
| `togglespecialworkspace` | — | `hl.dsp.workspace.toggle_special()` |
| `movetoworkspace` | `{ workspace, follow ? true }` | `hl.dsp.window.move({ workspace, follow })` — `follow = false` is a silent move |
| `resize` | `{ x, y }` | `hl.dsp.window.resize({ x, y })` |
| `submap-enter` | `{ submap }` | `hl.dsp.submap(…)` — `"default"` exits |

Generated internally for the workspace and navigation binds: `focus-workspace`,
`focus-direction`, `move-direction`, `window-drag`, `window-resize-mouse`.

An unknown dispatcher raises a Lua error naming the bind. Adding one means a case
in `lua/binds.lua` plus a row in the shortcuts preset contract.

> The shortcuts preset has a single consumer — this module — so changing its shape
> cannot affect Waybar or Quickshell. The *workspaces* preset is shared by three
> modules and is deliberately left alone; `splitMods` normalises its `"ALT_SHIFT"`
> spelling at the call site instead.

## Notes

- `systemd.enable = false` — Hyprland session integration is handled by UWSM, not the
  built-in systemd target
- All `exec` dispatchers are wrapped with `uwsm app --` for proper systemd session
  tracking
- Lua and hyprlang configs are mutually exclusive per session: switching needs a full
  logout/login, not `hyprctl reload`
- Host-specific settings live in `configurations/style/hyprland/`; monitors,
  workspaces and keybindings come from their own shared presets
