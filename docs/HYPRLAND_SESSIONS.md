# Enhancement Proposal: Workspace Sessions

**Status**: Accepted — all decisions settled, implementation not started
**Date**: 2026-09-12
**Module**: `homeManagerModules/hyprland/`, `configurations/style/workspaces/`
**Related**: [HYPRLAND-LUA-MIGRATION.md](HYPRLAND-LUA-MIGRATION.md), [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md)

---

## Goal

Work on several projects at once without moving windows by hand.

Today a project occupies the whole 3×3 grid: a terminal for an AI agent, an IDE, a
run/debug window, Postman, a browser. Starting a second project means shuffling
those windows around the same nine workspaces; taking a break for gaming means
shuffling again.

A **session** is one complete instance of the existing 3×3 grid. Switching session
re-points all three monitors at that session's workspaces simultaneously. Windows
never move — the workspaces they live on simply stop being displayed.

This is what KDE calls *Activities* and dwm/awesome call *tags*. The closest
Hyprland equivalents are [hyprtags](https://github.com/JoaoCostaIFG/hyprtags) and
[pyprland's workspace plugins](https://deepwiki.com/hyprland-community/pyprland/5.4-workspace-management-plugins),
neither of which matches this model — tags govern *which windows are visible*,
sessions govern *which set of nine workspaces is live*. The idea is a recognised
want upstream ([Hyprland discussion #10331](https://github.com/hyprwm/Hyprland/discussions/10331)).

---

## Why this is newly possible

It needed an external daemon holding state before the Lua migration. It no longer
does. Three primitives, all verified against the running compositor (0.56.0):

| Primitive | Verified |
|---|---|
| `hl.bind` accepts **a plain Lua function** as its dispatcher | the migration's own error message states it; confirmed in `hyprctl repl` |
| `monitor:set_workspace({ workspace })` | `hl.get_active_monitor().set_workspace` → `function` |
| `hl.dispatch`, `hl.get_monitors`, `hl.get_current_submap`, `hl.notification` | all present |

Reading `src/config/lua/objects/LuaMonitor.cpp`, `monitorSetWorkspace` **creates the
workspace if it does not exist** and moves it to that monitor, then changes to it
without stealing focus unless it is already the focused monitor:

```cpp
auto ws = State::workspaceState()->query().id(id).run();
if (!ws)
    ws = State::workspaceState()->create(id, (*ref)->m_id, name);
State::workspacePlacementController()->moveWorkspaceToMonitor(ws, ref->lock(), true, false);
(*ref)->changeWorkspace(ws, false, true, Desktop::focusState()->monitor() != *ref);
```

So sessions cost nothing until entered, and switching all three monitors at once
leaves focus where it was.

---

## Settled decisions

| # | Decision | Choice |
|---|---|---|
| **S1** | Workspace identity | **Numeric banding**: `id = (session - 1) * 10 + slot`. Session 1 is workspaces 1–9 — today's layout, unchanged |
| **S2** | Bar icons | **Per slot, not per id.** Slot 1 carries the same glyph in every session |
| **S3** | Session definition | **Hybrid**: exactly **one** session declared in the preset today; the rest exist dynamically. Adding a second named, persistent session later is then a preset edit, not a redesign |
| **S4** | Entry | `SESSION_SHORTCUT` = **`ALT+Escape`**, entering a `session` submap. Pressing it again returns to `default` |
| **S5** | In-submap keys | `ALT+1`…`ALT+9` → go to that session · `ALT+Tab` / `ALT+SHIFT+Tab` → cycle open sessions |
| **S6** | Switch semantics | **All three monitors switch simultaneously**, not just the focused one |
| **S7** | Within a session | The 3×3 grid behaves exactly as now — `A/Z/E · Q/S/D · W/X/C` (and the keypad) navigate the nine workspaces |
| **S8** | New sessions | Created **empty, on demand**. No pre-declaration |
| **S9** | Session restore | **Out of scope, deliberately.** Everything is closed at end of day; restoring would be counter-productive |
| **S10** | Notifications | Out of scope. A notification daemon showing *session / monitor / workspace* is planned separately |
| **S11** | Waybar | Will break (`persistent-workspaces` takes a static id list). Acceptable — Waybar is being retired. **Provided it degrades, not crashes** (see R1) |
| **S12** | Quickshell | A bar pill showing the current session and the available ones is planned as separate work |
| **S13** | "Open" session | One holding **at least one window**. Self-cleaning: closing the last window drops it out of the `ALT+Tab` ring |
| **S14** | State persistence | The `session` value and last-slot table are **in-memory only**; a compositor restart resets to session 1. Revisit only if restarts turn out to happen in practice |
| **S15** | Session count | **9**, band width 10 (ids up to 89). `ALT+1…9` covers all of them |
| **S16** | Universal binds | A small set carries `submap_universal` so it fires in *every* context — see [Universal binds](#universal-binds) |
| **S17** | Naming | The declared session is simply **`"1"`**. Names surface nowhere until the Quickshell pill exists, which will list the **open session numbers** (e.g. `1 3 4 8 9`) |
| **S18** | Switch feedback | `hl.notification.create` for now — free, no widget work. A centred Quickshell overlay stays a later option |
| **S19** | Submap indicator | None needed: the Quickshell bar already has a submap pill, which covers it |
| **S20** | Workspace rules | **Generated for every band** — 9 sessions × 9 slots = **81 `hl.workspace_rule` calls**, from the same preset data. See [Why 81 rules](#why-81-rules) |

### The grid, restated

The nine slots are an AZERTY-shaped mnemonic — **columns are monitors, rows are the
three workspaces on that monitor**:

| | code · `DP-3` | terminal · `DP-1` | browser · `HDMI-A-2` |
|---|---|---|---|
| row 1 | `A` → slot 1 | `Z` → slot 2 | `E` → slot 3 |
| row 2 | `Q` → slot 4 | `S` → slot 5 | `D` → slot 6 |
| row 3 | `W` → slot 7 | `X` → slot 8 | `C` → slot 9 |

Banding preserves it exactly:

| Session | Slots 1–9 map to ids |
|---|---|
| 1 (today) | 1, 2, 3, 4, 5, 6, 7, 8, 9 |
| 2 | 11, 12, 13, 14, 15, 16, 17, 18, 19 |
| 3 | 21 … 29 |
| *n* | `(n-1)*10 + slot` |

---

## Behaviour specification

### Entering and leaving

```
ALT+Escape            enter the `session` submap
ALT+Escape            (again) leave it
```

While the submap is active **only its binds fire** — every global bind is inert.
That is what frees `ALT+1…9` and `ALT+Tab`.

### Inside the submap

| Key | Effect |
|---|---|
| `ALT+1` … `ALT+9` | Switch to that session, creating it empty if new |
| `ALT+Tab` | Next open session |
| `ALT+SHIFT+Tab` | Previous open session |
| `ALT+Escape` | Return to `default` |

### Universal binds

Inside a submap **only that submap's binds fire** — every other bind in the config
is inert. Two consequences:

1. Each submap would otherwise need its own copy of the exit bind. Forget one and
   that submap is a keyboard dead-end, recoverable only via
   `hyprctl dispatch submap reset` from a TTY.
2. Things that should never depend on the current mode — taking a screenshot,
   opening a terminal because something has hung — stop working.

`submap_universal = true` marks a bind as firing in **every** context, default and
all submaps, defined once:

| Bind | Purpose |
|---|---|
| `ALT+Escape` | Toggle the `session` submap. The Lua function reads `hl.get_current_submap()`: empty → enter `session`; anything else → return to `default`. One definition makes it structurally impossible to get stuck in *any* submap |
| `mouse:277` / `SHIFT+mouse:277` | Screenshots should not care which mode is active |
| **Emergency terminal** | A floating terminal, centred on the focused window. Valuable precisely because it works when a submap has swallowed the keyboard or an application has hung. Implemented as an `exec` bind plus a window rule (`float`, `center`) |

### Switching

1. Record the current slot for each monitor against the outgoing session.
2. Set `session` to the target.
3. For each monitor, `set_workspace` to that session's remembered slot for that
   monitor (its first slot the first time).

Focus stays on whichever monitor had it, now showing the new session's workspace.

### Within a session

Unchanged. `ALT+<letter>` focuses a slot, `ALT+SHIFT+<letter>` moves the active
window to it silently — except the slot is resolved through the current session
band at press time.

**No rebinding happens on a session switch.** The nine navigation binds are bound to
Lua *functions* that read the `session` local when pressed, so there is exactly one
set of binds regardless of how many sessions exist.

---

## Architecture

### Where state lives

`session` and the per-session last-slot table are **Lua locals** in a checked-in
module, alongside `lua/binds.lua`:

```lua
local session  = 1
local lastSlot = {}    -- lastSlot[session][monitorName] = slot

local function wsFor(slot) return (session - 1) * 10 + slot end
```

Nothing external holds state: no daemon, no file, no `hyprctl` shelling out. This is
the direct payoff of Phase 3b putting real Lua in the config rather than generated
strings.

### How Quickshell learns the session — no new channel needed

The session is **derivable from the workspace id** the bar already tracks:

```
session = ((id - 1) // 10) + 1
slot    = ((id - 1) %  10) + 1
```

So the workspace strip keeps rendering slots 1–9 with today's glyphs (S2), and the
session pill reads the same Hyprland state Quickshell already subscribes to. No IPC,
no socket, no polling — which is why numeric banding was chosen over named
workspaces.

### Preset shape

`styleConfigs.workspaces` is read by **hyprland, waybar and quickshell**. Per the
coupling rules established in the migration doc, the change must be **additive**:
`workspaces_defined` keeps its current shape and becomes the *slot template*, with
session data added alongside. Renaming `id`, `icon` or `monitor` would break two
other modules.

---

### Why 81 rules

`hl.workspace_rule({ workspace, monitor })` answers one question: **when workspace N
comes into existence, which monitor does it belong to?** Today nine rules pin slots
1–9 to the three monitors.

Session *switching* does not need them — `monitor:set_workspace()` names the monitor
explicitly, so workspace 14 is created on whichever monitor asked for it.

Everything else does. `ALT+SHIFT+Q` (move the active window to slot 4) becomes
`hl.dsp.window.move({ workspace = "14" })`, which takes **no monitor argument**.
With no rule for workspace 14, Hyprland picks — most likely the focused monitor.
The 3×3 grid would hold in session 1 and quietly scramble everywhere else: slot 4
ending up on the terminal monitor because that is where you happened to be standing.

So the rules are generated for **every band**:

```nix
workspace_rule = lib.flatten (map (session:
  map (ws: {
    workspace = toString ((session - 1) * 10 + ws.id);
    monitor   = ws.monitor;
  }) workspaces.workspaces_defined
) (lib.range 1 9));
```

81 calls from the same preset data — a loop, not 81 lines of config. This also
covers paths outside our control: a window rule targeting a specific workspace, or
`hyprctl` from a script.

> Not yet verified empirically: where an unruled workspace actually lands. Worth a
> two-minute test in Phase A rather than trusting the reading above.

## Open questions

All design questions from the first draft are now settled (S13–S20). What remains
is empirical, to be answered during implementation rather than decided up front:

| # | To verify |
|---|---|
| **V1** | Where an **unruled** workspace actually lands — confirms the need for the 81 rules rather than inferring it |
| **V2** | Whether Waybar **degrades or faults** on ids outside its `persistent-workspaces` list (R1) |
| **V3** | Where focus ends up after three monitors switch at once (R4) |
| **V4** | The emergency terminal's exact form — which key, and whether `center` plus `float` is enough to place it over the focused window |

## Corrections found at runtime

Same failure mode as the Lua migration: the API reference is wrong, and nothing
offline catches it.

| Symptom | Wrong | Right |
|---|---|---|
| `Cannot set submap default, submap doesn't exist (wasn't registered!)` on `ALT+Escape` | `hl.dsp.submap("default")` — taken from the community API reference's own submap example | `hl.dsp.submap("reset")` |
| Session submap entered, but `ALT+1`…`ALT+9` did nothing — no error anywhere | `key = "1"` — a keysym, and on AZERTY the unshifted number row sends `ampersand` / `eacute` / `quotedbl` … | `key = "code:10"`…`"code:18"` — keycodes are layout-independent, and `wev` prints exactly these values |
| `HLMonitor.set_workspace: expected a workspace object or selector` on every monitor | `m:set_workspace({ workspace = … })` — a table | `m:set_workspace(…)` — the **bare selector**. `hl.dsp.window.move` takes a table (`tableOptWorkspaceSelector`); the monitor method takes it directly (`workspaceSelectorFromLuaSelectorOrObject`). Easy to conflate |
| In session 7, `ALT+A` went to workspace 1 instead of 61 — no error | `focus-slot` returned `hl.dsp.focus({ workspace = S.wsName(a.slot) })`, a dispatcher **built once at config load**, freezing the session-1 id into the bind | Return a **Lua closure** that calls `hl.dispatch(...)` at press time. Only closures re-read the session; a dispatcher value is evaluated when `hl.bind` is called |

`Actions::setSubmap` treats only `"reset"` and the empty string as "leave the
submap"; anything else is looked up as a registered submap name:

```cpp
ActionResult Actions::setSubmap(const std::string& submap) {
    if (submap == "reset" || submap.empty()) {
        Config::Actions::state()->m_currentSubmap = "";
        …
    }
    if (Keybinds::mgr()->registry().hasSubmap(submap)) { … }
    return std::unexpected(std::format("Cannot set submap {}, …", submap));
}
```

> `pcall` around `hl.dispatch(hl.dsp.submap("default"))` returns **success** — the
> action fails inside the compositor and surfaces on the runtime-error overlay
> rather than raising in Lua. The REPL is therefore no use for confirming this
> class of bug; the source is.

## Out of scope

Recorded so they are not re-litigated:

- **Session restore / auto-launch** (S9) — no relaunching apps, no working-directory
  or IDE-project restoration.
- **Notification integration** (S10) — a separate daemon.
- **Application cost** — not a concern: the same applications are already open; today
  they are moved by hand, which is the problem being solved.
- **Waybar support** (S11).

---

## Plan

### Phase A — banding and rules, no behaviour change

Introduce `wsFor(slot)` with `session` pinned to 1, so every id resolves to today's
value. Extend the workspaces preset additively. Generate all 81 `workspace_rule`
entries (S20).

**Verify**: the effective-config harness from the Lua migration reports an identical
call set apart from the 72 new workspace rules. Answer **V1** (where an unruled
workspace lands) and **V2** (Waybar's reaction) here, before anything depends on them.

### Phase B — the session submap

Add the `session` submap, the switch function, and the last-slot table. Sessions
become reachable. **Verify**: switch to session 2, confirm three empty workspaces
(11/12/13-ish per monitor), switch back, confirm the original windows and slots.

### Phase C — Quickshell session pill

Derive session and slot from the workspace id; render the current session plus the
open ones; keep the slot glyphs unchanged.

### Phase D — switch overlay

The centred name/number indicator. `hl.notification.create` first if it proves
sufficient, a Quickshell surface if not.

---

## Risks

| Risk | Mitigation |
|---|---|
| **R1 — Waybar faults rather than degrades** on ids outside its `persistent-workspaces` list | Accepted; will be tested directly. Disable `software.modules.waybar.enable` if it faults — Waybar is being retired anyway (V2) |
| **R2 — Stuck in a submap.** Every global bind is inert inside one | Settled by S16: `ALT+Escape` carries `submap_universal`, so one definition exits from *any* submap. `hyprctl dispatch submap reset` remains the last resort. The universal screenshot and emergency-terminal binds exist for the same reason |
| **R3 — The Lua API silently ignores unknown table fields** — the failure mode behind two bugs during the migration | Check every new field against `src/config/lua/bindings/`; keep using the mock-`hl` effective-config harness |
| **R4 — Focus lands somewhere unexpected** after three monitors switch at once | `changeWorkspace` suppresses focus for non-focused monitors, but confirm by relog rather than by reading (V3) |
| **R5 — The 3×3 grid scrambles outside session 1** because `window.move` has no monitor argument | Settled by S20: generate all 81 `workspace_rule` entries. See [Why 81 rules](#why-81-rules) |
| **R6 — 81 workspace rules slow startup or bloat the config** | They are one generated loop and plain data; measure the generated `hyprland.lua` size in Phase A and check compositor start time |


## Sources

- [Hyprland discussion #10331 — move workspace into group](https://github.com/hyprwm/Hyprland/discussions/10331) — the same want, upstream
- [hyprtags](https://github.com/JoaoCostaIFG/hyprtags) — dwm-style tags for Hyprland
- [pyprland workspace plugins](https://deepwiki.com/hyprland-community/pyprland/5.4-workspace-management-plugins)
- [Unlocking more than 10 workspaces](https://pedropinto.me/blog/an-update-on-unlocking-more-than-10-workspaces-in-hyprland/) — the submap modal-capture pattern this borrows from
- [Hyprland wiki — Binds](https://wiki.hypr.land/Configuring/Basics/Binds/) — submaps, `submap_universal`, catch-all binds
- `src/config/lua/objects/LuaMonitor.cpp` in the Hyprland source — `set_workspace` semantics
