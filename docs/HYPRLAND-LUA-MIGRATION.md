# Enhancement Proposal: Hyprland Lua Migration & Config Refactor

**Status**: Lua migration **done** (forced, 2026-08-30) — Phases 1–2 and 4–5 outstanding
**Date**: 2026-08-30, updated 2026-08-31
**Module**: `homeManagerModules/hyprland/`
**Related**: [ENHANCEMENT-PROFILES.md](ENHANCEMENT-PROFILES.md), [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md)

---

## Why now

Hyprland replaced its own `hyprlang` config language with embedded **Lua 5.4** in
0.55, and the old format is on a deprecation clock.

| Release | Date | What landed |
|---|---|---|
| **0.55** | 2026-05-09 | Lua 5.4 embedded as the config language; user-defined layouts; per-output ICC profiles |
| **0.56** | ~2026-07 | Large Lua API expansion (events, workspace/monitor queries, keyboard state, plugin queries); `stableid:` window-rule field; `disable_when_only` group bars; `no_auto_hdr`; silent move-to-monitor; XDG interactive dragging; `hyprctl` **Lua REPL** |
| **0.56.2** | 2026-08-05 | 16 backported fixes (tiling, fullscreen rendering, GL depth invalidation, CJK IME) |

Upstream's stated policy: hyprlang is supported for **"1–2 releases starting from
0.55"** and receives **no further feature development**. In practice the window
closed sooner than that reads: on 0.56.0 the generated hyprlang config was ignored
outright and the compositor booted its built-in defaults, which is what forced the
migration (see [Migration log](#migration-log--what-actually-happened)).

### Where this repo sits today

| Fact | Value |
|---|---|
| `hyprland` flake input | `github:hyprwm/Hyprland` (main), locked `c91fa5a` |
| Compositor actually running | **`Hyprland 0.56.0`**, commit `c91fa5ab…`, built 2026-08-29 (`hyprctl version`) |
| `programs.hyprland.package` (system, what runs) | flake input → `0.56.0+date=2026-08-29_c91fa5a` |
| `wayland.windowManager.hyprland.package` (HM) | **nixpkgs default → `0.56.2`** — a second, unused Hyprland in the closure (see D7) |
| `home-manager` input | `github:nix-community/home-manager` (master) |
| `home.stateVersion` | `25.05` (`homeManagerModules/default.nix:48`) — so `configType` is set explicitly, not inherited |
| Config format in use | **Lua**, `~/.config/hypr/hyprland.lua` (no `hyprland.conf`) |

---

## Migration log — what actually happened

The migration was **not** executed as the phased plan below describes. A routine
flake update on 2026-08-30 broke the desktop and forced the Lua flip in one step.

**Symptom**: Hyprland started with its built-in default configuration, ignoring the
generated config entirely. Nix evaluation succeeded and emitted only a warning
(`the default value of configType has changed from "hyprlang" to "lua"`), so nothing
failed at build time — the breakage was silent until login.

**Root cause**: Home Manager's Lua renderer
(`modules/services/window-managers/hyprland/lib.nix`) is a literal passthrough:

```nix
renderCall = name: value: "hl.${name}(${renderLuaArgs value})\n";
```

Every top-level `settings` key becomes `hl.<key>(...)` verbatim. Our keys were
hyprlang **section names**, so they rendered as `hl.general(...)`,
`hl.windowrule(...)`, `hl.workspace(...)` and `hl.exec-once(...)` — none of which
exist, and the last is not even valid Lua (it parses as `hl.exec - once`). Hyprland
rejected the file and fell back to defaults.

Stylix was never implicated: `modules/hyprland/hm.nix` already branches on
`configType` and nests its palette under `config` for Lua.

### Corrections found against the live compositor

Offline validation (`luac -p`, call-name audit, bind-count parity) caught nothing
here — every one of these was a **semantic** error surfaced only by running it. The
community `hl.*` API reference was wrong on two counts.

| Symptom at runtime | Wrong | Right |
|---|---|---|
| `hl.window.fullscreen: invalid mode "maximize" (expected fullscreen/maximized)` | `mode = "maximize"` | `mode = "maximized"` |
| `hl.bind: dispatcher must be a dispatcher …` | — | knock-on: the failed `fullscreen` call returned `nil`, so `hl.bind` received `nil` |
| `error setting 'general.gaps_out': css_gap type requires an integer or a table with optional "top"/"right"/"bottom"/"left"` | `gaps_out = "10,3,5,3"` | `{ top = 10; right = 3; bottom = 5; left = 3; }` — hyprlang's comma list was CSS order |
| `attempt to call a nil value (field 'exec_once')` | `hl.exec_once(cmd)` — **does not exist**, despite being documented | `hl.on("hyprland.start", function() hl.exec_cmd(…) end)` |
| `hl.window_rule: field 'max_size': expression vec2 type requires exactly 2 elements` | `max_size = { w = 1084; h = 653; }` | `max_size = [ 1084 653 ]` → `{ 1084, 653 }` |

**Lesson for the remaining phases**: syntax checking and call-name auditing prove
almost nothing about this API. Field *types* (`css_gap`, `vec2`) and enum *spellings*
are only discoverable by running the compositor. Change one surface at a time and
relog.

### What the flip actually shipped

`homeManagerModules/hyprland/home.nix` only — a key remapping, not the Strategy A
rewrite:

| hyprlang | Lua |
|---|---|
| `general`, `input` sections | nested under `config` → one `hl.config({…})` |
| `exec-once` | `hl.on("hyprland.start", function() … end)` |
| `monitor` string | `hl.monitor({ output, mode, position, scale })` |
| `bind` strings | `hl.bind(keys, hl.dsp.*, { description })` via `_args` + `mkLuaInline` |
| `bindm` | folded into `bind` with `{ mouse = true }` |
| `windowrule` | `window_rule` with `match = { class, title }` |
| `workspace` | `workspace_rule` |

Modifiers converted `ALT_SHIFT` → `ALT+SHIFT`; `mapDirectionToHyprland` (Left→`l`)
replaced by `hl.dsp.focus({ direction = "left" })`; and every bind now carries the
`description` from the shortcuts preset, which was previously collected and discarded.

**Verified**: 73 binds emitted, matching the 73 `bind`+`bindm` lines of the old
`hyprland.conf` exactly; only real API functions emitted (`hl.bind` ×73, `hl.config`,
`hl.monitor` ×3, `hl.on`, `hl.window_rule` ×4, `hl.workspace_rule` ×10);
`hyprctl getoption general:gaps_out` returns `10 3 5 3`, matching the old value.

**Still Strategy B in shape** — every dispatcher is a `mkLuaInline` string. This was
the emergency fix, not the target architecture. Strategy A (D1) remains the plan.

---

## Current state review

> Written before the migration; describes the module as it stood at 129 lines. The
> Lua flip addressed the string-concatenation and dispatcher issues below; items 2, 4
> and 5 are still outstanding and are what Phases 1–2 exist to fix.

`homeManagerModules/hyprland/home.nix` was 129 lines and showed its age as the first
module written for this repo.

### 1. Everything is string concatenation

Binds are assembled as `"${mod1}, ${key}, ${dispatcher-type}, ${command}"`, with a
three-way conditional whose only job is deciding whether to splice in `env` and the
`uwsm app --` wrapper:

```nix
if shortcut.command != null && shortcut.command != "" && shortcut.dispatcher-type == "exec" && shortcut.env != "" then
  "${shortcut.mod1}, ${shortcut.key}, ${shortcut.dispatcher-type}, ${shortcut.env} uwsm app -- ${shortcut.command}"
else if ... 
```

Every value is stringly-typed. A typo in a dispatcher name is a runtime failure in
the compositor, not a Nix evaluation error.

### 2. The shortcut schema is too thin for what comes next

```nix
{ description; mod1; key; dispatcher-type; command; env; }
```

No second modifier, no bind flags (`locked` / `release` / `repeat`), and **no submap
field** — which is precisely what the next task needs.

### 3. `description` is collected and then discarded

Every entry in `configurations/software/shortcuts/presets/mastodant-1.nix` carries a
`description`. Nothing consumes it. Lua's `hl.bind` takes `description` as a native
bind option, so this data finally has somewhere to go — and becomes queryable at
runtime, which the planned Quickshell submap widget can use.

### 4. Host data lives in the module

Window rules (satty, `Xdg-desktop-portal-gtk`, Brave, VSCodium) and the
`special:special` workspace rule are hardcoded in `home.nix`. This is the same
violation already corrected for Quickshell by moving layout into
`configurations/style/quickshell/`. Hyprland never got that treatment: there is **no
`configurations/` preset for Hyprland's own settings at all**, only the shared
`shortcuts` preset.

### 5. Smaller issues

- Dead stubs: `misc = {}`, `cursor = {}`, and a `general` block holding one key.
- Screenshot binds are inline shell in the shortcuts preset, carrying the author's
  own `TODO :: 2025-06-10 :: Change this to be modular on a screenshot config standalone`.
- `hyprland-windowsrules.md` sits at the repo root rather than in `docs/`.
- Comments link the `0.48.0` wiki; the module README documents the old schema.
- `mapDirectionToHyprland` (Left→`l`) exists only because the dispatcher took a
  single-letter string; the Lua API takes `{ direction = "left" }` instead.

---

## Preset coupling: what a schema change would actually break

This is the question that gates how aggressive the refactor can be. The presets are
shared, but **not equally** — measured by direct field access across the repo:

| Preset / field | hyprland | waybar | quickshell |
|---|:--:|:--:|:--:|
| `styleConfigs.workspaces` → `workspaces_defined[].id` | ✓ | ✓ | ✓ |
| `…workspaces_defined[].icon` | — | ✓ | ✓ |
| `…workspaces_defined[].monitor` | ✓ | — | ✓ |
| `…workspaces_defined[].shortcut` | ✓ | — | — |
| `…workspaces_defined[].mod` / `.mod-shift` | ✓ | — | — |
| `…navigation[]` (direction, shortcut, mod) | ✓ | — | — |
| `hardwareConfigs.monitors` → `definition[]` | ✓ | — | — |
| `hardwareConfigs.monitors` → `disposition.*` | — | — | ✓ |
| `softwareConfigs.shortcuts` → `shortcuts-definition` | ✓ | — | — |

Read paths that make this precise:

- **Waybar** projects rather than passes through. `homeManagerModules/waybar/utils.nix:9`
  builds its workspace module from `ws.id` and `ws.icon` only:
  ```nix
  format-icons = builtins.listToAttrs (
    lib.map (ws: { name = toString ws.id; value = ws.icon; }) ws_config.workspaces
  );
  persistent-workspaces = { "*" = lib.map (ws: ws.id) ws_config.workspaces; };
  ```
- **Quickshell** reads `id` / `icon` / `monitor` (`home.nix:107-109`) and
  `monitors.disposition.*` (`home.nix:113,161`).
- **Waybar** receives `monitors` only to feed `workspaces.apply`; its own bar-to-screen
  binding is hardcoded (`screen = "HDMI-A-2"` in the status-bars preset).

### The three rules that follow

1. **`softwareConfigs.shortcuts` has exactly one consumer** — `hyprland/home.nix:11`.
   Widening the shortcut schema (adding `mod2`, `flags`, `submap`) **cannot break
   Waybar or Quickshell.** This is free.
2. **Adding fields to `workspaces_defined` is safe.** All three consumers read named
   fields; none iterate keys or serialize the entry wholesale. Extra keys are ignored.
3. **Renaming or removing `id`, `icon`, `monitor`, or `disposition.*` breaks two
   other modules.** These are the load-bearing names. `shortcut`, `mod`, `mod-shift`,
   `navigation`, and `monitors.definition` are hyprland-only and can be reshaped freely.

**Therefore**: the refactor does not need to touch the shared presets at all.
Hyprland-specific data (window rules, submaps, `general`/`input`/`misc` sections)
belongs in a **new** `configurations/software/hyprland/` preset, leaving
`workspaces` and `monitors` untouched. Waybar and Quickshell keep working by
construction, not by careful review.

---

## Decision D1 — how Lua gets produced from Nix

Three viable strategies. All examples below encode the **same real slice** of this
config: the three monitors, workspace 1 (`ALT+A` / `ALT+KP_1` to focus,
`ALT SHIFT` to move), the `ALT+T` terminal bind, the Brave popup window rule, and a
resize submap.

### Strategy A — generated data + handwritten Lua *(recommended)*

Nix emits a **data-only** Lua table from the presets; handwritten Lua modules consume
it. This is the Quickshell `Config.qml` idiom, applied to Hyprland.

**Preset** — `configurations/software/hyprland/presets/mastodant-1.nix` (new):

```nix
{
  apply = { pkgs, defaults, ... }: {
    sections = {
      general = { gaps_out = "10,3,5,3"; };
      input   = { kb_layout = "fr"; numlock_by_default = true; };
    };

    window-rules = [
      { name = "brave-popup"; match = { class = "brave"; };
        float = true; center = true; no_initial_focus = true;
        max_size = { w = 1084; h = 653; }; }
    ];

    submaps = {
      resize = {
        description = "Resize mode";
        enter = "SUPER+R";
        binds = [
          { key = "h"; resize = { x = -40; y = 0; }; }
          { key = "l"; resize = { x =  40; y = 0; }; }
        ];
      };
    };
  };
  autostart = [ ];
}
```

**Module** — `homeManagerModules/hyprland/home.nix` (excerpt):

```nix
  wsEntries = lib.concatMapStringsSep ",\n" (w:
    "    { id = ${toString w.id}, monitor = \"${w.monitor}\", "
  + "keys = { ${lib.concatMapStringsSep ", " (k: "\"${k}\"") w.shortcut} } }"
  ) workspaces.workspaces_defined;

  dataLua = ''
    -- GENERATED by homeManagerModules/hyprland/home.nix. Do not edit.
    return {
      mods = { ws = "ALT", ws_shift = "ALT SHIFT" },
      monitors = {
    ${monitorEntries}
      },
      workspaces = {
    ${wsEntries}
      },
      binds = {
    ${bindEntries}
      },
    }
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    configType = "lua";
    extraLuaFiles = {
      "data"    = { content = dataLua;          autoLoad = false; };  # required by the rest
      "binds"   = { content = ./lua/binds.lua;   };                   # auto-required
      "rules"   = { content = ./lua/rules.lua;   };
      "submaps" = { content = ./lua/submaps.lua; };
    };
  };
}
```

**Generated** — `~/.config/hypr/data.lua`:

```lua
-- GENERATED by homeManagerModules/hyprland/home.nix. Do not edit.
return {
  mods = { ws = "ALT", ws_shift = "ALT SHIFT" },
  monitors = {
    { output = "DP-3",     mode = "1920x1080@60",  position = "0x1440",    scale = 1 },
    { output = "HDMI-A-2", mode = "3440x1440@100", position = "200x0",     scale = 1 },
    { output = "DP-1",     mode = "1920x1080@60",  position = "1920x1440", scale = 1 },
  },
  workspaces = {
    { id = 1, monitor = "DP-3", keys = { "A", "KP_1" } },
    { id = 4, monitor = "DP-3", keys = { "Q", "KP_4" } },
    -- …
  },
  binds = {
    { keys = "ALT+T", exec = "uwsm app -- kitty", description = "Open Terminal" },
    -- …
  },
}
```

**Handwritten** — `homeManagerModules/hyprland/lua/binds.lua` (checked into the repo):

```lua
local d = require("data")

for _, m in ipairs(d.monitors) do hl.monitor(m) end

-- Application shortcuts, from the shortcuts preset.
for _, b in ipairs(d.binds) do
  hl.bind(b.keys, hl.dsp.exec_cmd(b.exec), { description = b.description })
end

-- Workspace focus + move, for every key bound to that workspace.
for _, ws in ipairs(d.workspaces) do
  for _, key in ipairs(ws.keys) do
    hl.bind(d.mods.ws .. "+" .. key,
            hl.dsp.focus({ workspace = tostring(ws.id) }),
            { description = "Workspace " .. ws.id })
    hl.bind(d.mods.ws_shift .. "+" .. key,
            hl.dsp.window.move({ workspace = tostring(ws.id), silent = true }),
            { description = "Move to workspace " .. ws.id })
  end
end
```

**Handwritten** — `lua/submaps.lua`:

```lua
hl.define_submap("resize", function()
  hl.bind("h",      hl.dsp.window.resize({ x = -40, y = 0 }))
  hl.bind("l",      hl.dsp.window.resize({ x =  40, y = 0 }))
  hl.bind("Escape", hl.dsp.submap("default"))
end)

hl.bind("SUPER+R", hl.dsp.submap("resize"), { description = "Resize mode" })
```

**Trade-off**: two languages instead of one, and the Lua files are not type-checked by
Nix. In exchange, the loop that generates 36 workspace binds is three lines of Lua
instead of a `lib.flatten (map (map …))`, and events/timers/`hl.on` are directly
reachable.

---

### Strategy B — pure Home Manager `settings`

Everything stays in Nix; HM transpiles. Its rules (from
`modules/services/window-managers/hyprland/lib.nix`): each top-level attribute becomes
an `hl.<name>(...)` call, list values emit **one call per element**, `_args` renders a
multi-argument call, `_var` emits a `local`, and `lib.generators.mkLuaInline` passes
raw Lua through.

**Module** — `homeManagerModules/hyprland/home.nix`:

```nix
let
  inherit (lib.generators) mkLuaInline;
in {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings = {
      monitor = map (m: {
        output   = m.name;
        mode     = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
        position = "${toString m.position.x}x${toString m.position.y}";
        scale    = m.scale;
      }) activeMonitorConfig.definition;

      general = { gaps_out = "10,3,5,3"; };

      bind =
        # ALT+T → terminal
        [ { _args = [
              "ALT+T"
              (mkLuaInline "hl.dsp.exec_cmd('uwsm app -- ${defaults.terminal.command}')")
              { description = "Open Terminal"; }
            ]; } ]
        ++
        # workspace focus + move, both key rows
        lib.flatten (map (ws: map (k: [
          { _args = [ "${ws.mod}+${k}"
                      (mkLuaInline "hl.dsp.focus({ workspace = '${toString ws.id}' })")
                      { description = "Workspace ${toString ws.id}"; } ]; }
          { _args = [ "${ws.mod-shift}+${k}"
                      (mkLuaInline "hl.dsp.window.move({ workspace = '${toString ws.id}', silent = true })")
                      { description = "Move to workspace ${toString ws.id}"; } ]; }
        ]) ws.shortcut) workspaces.workspaces_defined);

      window_rule = [
        { name = "brave-popup";
          match = { class = "brave"; };
          float = true; center = true; no_initial_focus = true;
          max_size = "1084 653"; }
      ];
    };

    submaps.resize = {
      onDispatch = "reset";
      settings.bind = [
        { _args = [ "h" (mkLuaInline "hl.dsp.window.resize({ x = -40, y = 0 })") ]; }
        { _args = [ "l" (mkLuaInline "hl.dsp.window.resize({ x =  40, y = 0 })") ]; }
      ];
    };
  };
}
```

**Generated** — `~/.config/hypr/hyprland.lua`:

```lua
hl.monitor({ mode = "1920x1080@60", output = "DP-3", position = "0x1440", scale = 1 })
hl.monitor({ mode = "3440x1440@100", output = "HDMI-A-2", position = "200x0", scale = 1 })
hl.monitor({ mode = "1920x1080@60", output = "DP-1", position = "1920x1440", scale = 1 })

hl.config({ general = { gaps_out = "10,3,5,3" } })

hl.bind("ALT+T", hl.dsp.exec_cmd('uwsm app -- kitty'), { description = "Open Terminal" })
hl.bind("ALT+A", hl.dsp.focus({ workspace = '1' }), { description = "Workspace 1" })
hl.bind("ALT SHIFT+A", hl.dsp.window.move({ workspace = '1', silent = true }), { description = "Move to workspace 1" })
hl.bind("ALT+KP_1", hl.dsp.focus({ workspace = '1' }), { description = "Workspace 1" })
-- … 32 more, one line each

hl.window_rule({ center = true, float = true, match = { class = "brave" }, max_size = "1084 653", name = "brave-popup", no_initial_focus = true })
```

**Trade-off**: one language, fully declarative, and the preset system stays in charge.
But every dispatcher is a `mkLuaInline` string — so we have swapped hyprlang string
concatenation for **Lua** string concatenation and gained little type safety. Lua
control flow, `hl.on` events and timers are effectively out of reach. Key order in
generated tables is the generator's, not ours.

> ⚠️ **Known rough edge.** [home-manager#9468](https://github.com/nix-community/home-manager/issues/9468)
> reported `settings` producing invalid Lua (`<name> expected near '$'`) for a
> `monitor` string plus an `env` list, and was **closed as not planned**. Our
> screenshot binds contain `$(grim …)`, `$(slurp)` and `$HOME`. Under this strategy
> those strings pass through the transpiler; under A and C they sit in a file we
> control. This must be tested before committing to B.

---

### Strategy C — fully handwritten Lua

Nix wires the package and session only; `hyprland.lua` is checked in as a static file.

**Module**:

```nix
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    configType = "lua";
    extraLuaFiles."hypr-config" = { content = ./lua/hypr-config.lua; };
  };
}
```

**Checked in** — `lua/hypr-config.lua`:

```lua
hl.monitor({ output = "DP-3",     mode = "1920x1080@60",  position = "0x1440",    scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "3440x1440@100", position = "200x0",     scale = 1 })
hl.monitor({ output = "DP-1",     mode = "1920x1080@60",  position = "1920x1440", scale = 1 })

hl.config({ general = { gaps_out = "10,3,5,3" },
            input   = { kb_layout = "fr", numlock_by_default = true } })

hl.bind("ALT+T", hl.dsp.exec_cmd("uwsm app -- kitty"), { description = "Open Terminal" })

for _, k in ipairs({ "A", "KP_1" }) do
  hl.bind("ALT+" .. k, hl.dsp.focus({ workspace = "1" }))
end

hl.window_rule({ name = "brave-popup", match = { class = "brave" },
                 float = true, center = true, max_size = { w = 1084, h = 653 } })
```

**Trade-off**: shortest, most readable, matches upstream docs exactly, zero
transpiler risk. But monitor names, workspace ids and default programs are now
**duplicated** rather than derived — Waybar and Quickshell would keep reading the
presets while Hyprland reads a hand-maintained copy. The three would drift on the
next monitor change. This abandons the central premise of the repo.

---

### Comparison

| | A — generated data + Lua | B — pure `settings` | C — handwritten |
|---|---|---|---|
| Preset system preserved | ✅ fully | ✅ fully | ❌ abandoned for Hyprland |
| Single source of truth with Waybar/Quickshell | ✅ | ✅ | ❌ drifts |
| Submaps | ✅ native `hl.define_submap` | ⚠️ via HM `submaps` option | ✅ native |
| Events / timers / `hl.on` | ✅ | ❌ | ✅ |
| Exposed to HM transpiler bugs | ⚠️ data tables only | ❌ everything | ✅ not at all |
| Languages to maintain | 2 | 1 | 2 (Nix wiring + Lua) |
| Lua files reviewable as Lua | ✅ | ❌ generated | ✅ |
| Matches existing repo idiom | ✅ = Quickshell `Config.qml` | partly | ❌ |

**Recommendation: A.** It is the pattern already proven in this repo — Nix owns the
*data*, a hand-written runtime file owns the *behaviour* — and it keeps the
transpiler on the least dangerous surface (flat data tables, no `$`-bearing shell
strings routed through a generator with an open bug).

---

## Open decisions

| # | Decision | Status |
|---|---|---|
| **D3** | New preset location: `configurations/software/hyprland/` or `configurations/style/hyprland/`? Hyprland is a compositor (software) but owns gaps/rounding (style). Quickshell precedent put layout under `style/`. | Open |
| **D4** | Which submaps to define, and which existing global binds move into them | Open — see [Submap candidates](#submap-candidates) |
| **D5** | Bump `home.stateVersion` to `26.05` (and let `configType` default), or set `configType = "lua"` explicitly and leave `stateVersion` alone? | **Proposed**: set explicitly; a stateVersion bump has repo-wide effects unrelated to Hyprland |
| **D6** | Modularize the screenshot commands (the 2025-06-10 TODO) as part of this work, or leave for later? | Open |
| **D7** | `wayland.windowManager.hyprland.package` resolves to nixpkgs `0.56.2` while the session runs the flake input `0.56.0` — pin it to the same input, or set it to `null`? HM uses it only for the `onChange` reload hook, but it pulls a second Hyprland build into the closure | Open |

### Settled

| Decision | Choice | Rationale |
|---|---|---|
| **D2 — sequencing** | **Decided by events**: the 2026-08-30 flake update broke the desktop, so the Lua flip happened first, in one step, as an emergency fix. Phases 1–2 became post-hoc cleanup rather than de-risking groundwork | The phased plan assumed hyprlang kept working while we refactored; it did not |
| **D1 — config generation strategy** | **Strategy A** — Nix generates a data-only `data.lua` from the presets; handwritten Lua modules consume it via `extraLuaFiles` | Same idiom as the Quickshell `Config.qml` / `Theme.qml` split already proven in this repo. Keeps the preset system as the single source of truth shared with Waybar/Quickshell, keeps `$`-bearing shell strings out of the HM transpiler (#9468), and leaves `hl.define_submap` / `hl.on` / timers directly reachable for the submap work |
| Migrate to Lua at all | **Yes** | hyprlang is frozen and slated for removal within 1–2 releases of 0.55; we are already on a 0.56.x compositor |
| Touch `workspaces` / `monitors` preset shapes | **No** | Three modules read them; hyprland-only data goes in a new preset instead (see [Preset coupling](#preset-coupling-what-a-schema-change-would-actually-break)) |
| Widen the `shortcuts` preset schema | **Yes** | Single consumer — zero blast radius |
| Keep `uwsm app --` wrapping | **Yes** | Session tracking is unchanged by the config language |

---

## Plan

Phase 3 shipped first, out of order and under pressure (see
[Migration log](#migration-log--what-actually-happened)). The remaining phases now
run **on top of a working Lua config**, which changes their verification gate: the
baseline to diff against is the generated `hyprland.lua`, not `hyprland.conf`.

### Phase 3 — Flip to Lua ✅ **Done** (2026-08-30)

- `configType = "lua"` set explicitly (`home.stateVersion` left at `25.05`).
- Monitors, binds, window rules, workspace rules and startup commands ported.
- Window rules converted to the typed form `hl.window_rule({ name, match = { class }, … })`.
- `mapDirectionToHyprland` dropped for `hl.dsp.focus({ direction = "left" })`.
- Shipped as a key remapping inside `settings`, **not** the Strategy A architecture —
  every dispatcher is still a `mkLuaInline` string. Phase 3b below closes that gap.

### Phase 3b — Land Strategy A *(new)*

- Generate a data-only `data.lua` from the presets; move bind/rule construction into
  handwritten Lua under `extraLuaFiles`, per [Strategy A](#strategy-a--generated-data--handwritten-lua-recommended).
- Removes the `mkLuaInline` string-concatenation that the emergency fix left behind,
  and is a prerequisite for using `hl.on` / timers in Phase 4.
- **Verify**: generated `hyprland.lua` produces the same call set (73 binds,
  4 window rules, 10 workspace rules); relog.

### Phase 1 — Extract host data into a preset *(no behaviour change)*

- Create `configurations/style/hyprland/` (D3) with `default.nix` (the `active` enum
  option) and `presets/mastodant-1.nix`.
- Move out of `home.nix`: window rules, the `special:special` workspace rule, and the
  `general` / `input` sections.
- Wire it through `custom-config-generator.nix` exactly as
  `configurations/style/quickshell/` is wired.
- **Verify**: diff the generated `hyprland.lua` before/after — it should be identical
  or trivially reordered.

### Phase 2 — Widen the shortcut schema *(no behaviour change)*

- Extend `ShortcutDef` to `{ description; mods; key; dispatcher; args; flags; submap; env; }`
  — `mods` replacing `mod1` as a list, `flags` for `locked`/`release`/`repeat`,
  `submap` naming the submap an entry belongs to (null = global).
- Update the contract docstring in `configurations/software/shortcuts/default.nix`.
- Replaces the `mkDispatcher` string table with typed dispatcher data.
- **Verify**: generated `hyprland.lua` diff is empty.

### Phase 4 — Introduce submaps

- Define the submaps chosen in D4; move the corresponding global binds into them.
- **Verify**: `hl.get_current_submap()` reports correctly; `Escape` always returns to
  `default` from every submap.

### Phase 5 — 0.56 features, docs, cleanup

- Evaluate `stableid:` window rules for the Brave main-window-vs-popup case, where
  class matching is already documented as fragile.
- Resolve D7 (the duplicated Hyprland package).
- Move `hyprland-windowsrules.md` into `docs/`; replace `0.48.0` wiki links.
- Remove the stray `~/.config/hypr/old.hyprland.lua` and `hyprland.conf.bak` once the
  Lua config has proven itself.
- Record the outcome in this document.

---

## Submap candidates

Drawn from binds that currently occupy the global namespace or that the design implies:

| Submap | Enter | Contains |
|---|---|---|
| `resize` | `SUPER+R` | directional resize, `Escape` to exit |
| `move` | `SUPER+M` | move window to workspace/monitor without the `ALT SHIFT` prefix on every key |
| `screenshot` | `SUPER+S` | region / fullscreen / window — replaces the two inline `mouse:277` binds |
| `power` | `SUPER+P` | lock, logout, suspend, reboot — currently only `SUPER+L` exists |

The active submap is exposed by `hl.get_current_submap()` and the `keybinds.submap`
event, which is what the planned Quickshell submap widget will consume — replacing
the static `{ w = "stub"; icon = "f11c"; label = "resize"; }` entries currently in
`configurations/style/quickshell/presets/screen-bars.nix`.

---

## Risks

| Risk | Status / mitigation |
|---|---|
| **A flake update silently breaks the desktop** — evaluation succeeds, the compositor falls back to defaults at login | **Materialised 2026-08-30.** Nix build success proves nothing about config validity. Pin `hyprland` to a known-good rev and bump deliberately; keep a TTY login available |
| **Offline validation gives false confidence** — `luac -p` and call-name audits pass on semantically invalid config | **Materialised.** Five runtime errors survived a clean syntax check (see the corrections table). Treat `luac -p` as a floor, not a gate; change one surface at a time and relog |
| **Third-party API docs are wrong** — `hl.exec_once` is documented but does not exist | **Materialised.** Prefer patterns verifiable in real source (Home Manager's `lib.nix`, Stylix's `modules/hyprland/hm.nix`) over the community reference |
| HM Lua transpiler emits invalid Lua for `$`-bearing strings ([#9468](https://github.com/nix-community/home-manager/issues/9468), closed as not planned) | Did **not** materialise — the screenshot binds' `$(grim …)` / `$HOME` passed through intact. Strategy A (Phase 3b) removes the exposure anyway |
| Lua and hyprlang configs are mutually exclusive per session | Confirmed: switching needs a full logout/login, not `hyprctl reload` |
| Upstream Lua API still moving (0.56 expanded it substantially) | The flake input tracks `main`; each bump can change field types and enum spellings, which only a relog will reveal |
| Waybar/Quickshell regression from preset edits | Not yet exercised — Phases 1–2 do not touch shared preset shapes; the coupling table above is the check |
| Two Hyprland builds in the closure (D7) | HM's package (`0.56.2`) differs from the running one (`0.56.0`); only affects the `onChange` reload hook today |

---

## Sources

- [Lua-ification of Hyprland configs](https://hypr.land/news/26_lua/) — official announcement, deprecation policy
- [Hyprland 0.56 release notes](https://hypr.land/news/update56/) · [v0.56.0](https://github.com/hyprwm/Hyprland/releases/tag/v0.56.0) · [v0.56.2](https://github.com/hyprwm/Hyprland/releases/tag/v0.56.2)
- [Hyprland 0.55 Released With Lua-Based Configuration](https://www.phoronix.com/news/Hyprland-0.55-Wayland-Comp)
- [`hl.*` Lua API reference](https://alejandrominaya.github.io/hyprland-lua-docs/)
- [Upstream example `hyprland.lua`](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua)
- [Home Manager `wayland.windowManager.hyprland` options](https://mynixos.com/home-manager/options/wayland.windowManager.hyprland)
- [home-manager#9468 — settings won't generate correct lua config](https://github.com/nix-community/home-manager/issues/9468)
- [hyprlang2lua converter](https://github.com/EIonTusk/hyprlang2lua) — possible cross-check for the Phase 3 port
