# Enhancement Proposal: Workspace Sessions

**Status**: Phases A–C done — D/E/F outstanding; submap survey + backlog recorded
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
| **S21** | Cross-session window move | `ALT+SHIFT+1..9` inside the submap sends the focused window to the **same slot** in the target session — only the band changes. Silent (`follow = false`), matching `ALT+SHIFT+<letter>` within a session |

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
| `ALT+SHIFT+1` … `ALT+SHIFT+9` | Move the focused window to the same slot in that session. In session 3 on workspace 25 (slot 5), `ALT+SHIFT+1` sends it to workspace 5. Focus stays put |
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

## Submap survey — prior art and candidates

Recorded 2026-09-12. Cross-cutting rather than session-specific, kept here because
the `session` submap is the first one built and this is the active plan.

### Candidate submaps

| Submap | Leader | Contents | Status |
|---|---|---|---|
| `session` | `ALT+Escape` | switch · move window · cycle | **Built** |
| `resize` | `SUPER+R` | directional resize, split ratio, preset sizes | **Postponed** — depends on a window-positioning decision not yet taken |
| `window` | `SUPER+W` | move-to-monitor, groups/tabs, pin, center, pseudo | **Postponed** — same decision; may subsume `resize` |
| `screenshot` | `SUPER+S` | region / window / fullscreen / delayed, clipboard variants, OCR | Open — independent of the above, and settles D6 |
| `power` | `SUPER+P` | lock, logout, suspend, reboot, poweroff | Open — only `SUPER+L` (logout) exists today |
| `minimal` | `SUPER+grave` | a stripped set, so an app can reclaim keys like `Alt-Tab` | Open |

`SUPER` remains nearly empty (`Q`, `Space`, `L`, `SHIFT+Q`), so none of these collide.

### Recurring submaps in the wild

The set is narrow and repeats across configs: **resize** (the wiki's own example,
near-universal), **window/move**, **screenshot**, **launcher/apps**, **utils**,
**power/session**, and **minimal**.

Broader patterns: a **leader key** routing to sub-modes (Emacs/Spacemacs style),
**app-key reclaim**, **nested keychords**, and **workspace overflow** (rejected
here — see [Goal](#goal); the monitor-role grid makes it unnecessary).

### Omarchy

Also runs a **Lua config** now, in three layers (base / theme / user override) with
`~/.config/hypr/hyprland.lua` as the entry point — so this repo is not early to the
migration.

- **Binding themes as a swappable set** — ships a "DHH" default and a "vim"
  alternative. **This repo already supports that**: `software.shortcuts.active` is
  an enum over presets, so a `mastodant-1-vim` preset is a new file, not a refactor.
- **The `minimal` submap** ([discussion #2675](https://github.com/omacom/omarchy/discussions/2675))
  — `SUPER+grave` toggles a stripped binding set so an application can have its own
  keys back.
- **Nested command menus** — `Super+Ctrl+C` opens a *capture* menu rather than firing
  an action directly.
- **`CapsLock M <letter>`** for emoji/text expansion: a parallel input system
  entirely outside the Super scheme.
- Unified clipboard — `Super+C/X/V` everywhere including terminals, deliberately
  breaking the `Ctrl+Shift` convention.

That same discussion independently concluded that *"Waybar showing when you're in a
non-default submap is helpful"* — which is the submap pill built here.

### ML4W

Uses **no submaps at all**; every binding is flat. Its value is elsewhere:

- ⚠️ **Explicit AZERTY handling.** It reads the layout from `input.lua` and maps
  different keysyms "since AZERTY requires Shift for numbers, preventing direct digit
  binding" — independent confirmation of the trap hit here. Their fix is per-layout
  keysym mapping; `code:10`..`code:18` is layout-independent and preferable.
- **Workspace switching by mouse scroll** (`mainMod + mouse_down/up`) — cheap to add
  to the Quickshell workspace strip, and session-aware for free.
- **Screenshot OCR** — text extraction from a region; a strong candidate for the
  `screenshot` submap.
- Game-mode toggle; instant-vs-interactive screenshot variants.

### Noctalia

The closest comparison: the same bet (a Quickshell shell) taken further. One layer
owns **bar, dock, launcher, control center, notifications, wallpaper picker, OSD
overlays, lock screen, session panel and desktop widgets**, so visual consistency
comes free — the same reasoning as `Sys.qml`, scaled up.

Relevant to [Phase F](#phase-f--redesign) and to QUICKSHELL-SHELL.md stages 4–6:

- **OSD overlays** (volume, brightness) — currently handled by **avizo**; folding
  them into Quickshell drops a dependency and matches the bar.
- **Control center** — one panel instead of three separate popovers.
- **Script-backed custom widgets** — a generic widget type driven by a shell command,
  letting the preset add pills without new QML.
- **Config hot-reload** — worth noting the opposite is true here: Home Manager swaps
  a symlink whose resolved store path never changes, so the file watcher does not
  fire and Quickshell must be restarted manually after every rebuild.

### Ranked take

1. **`minimal` submap** — smallest change with real daily value
2. **`screenshot` submap + OCR** — also settles D6
3. **Mouse-scroll workspace switching** on the bar
4. **OSD in Quickshell** — replaces avizo, feeds Phase F
5. **A vim binding preset** — near-free given the preset system

## Backlog — triaged, pending discussion

Triaged 2026-09-12 from the [submap survey](#submap-survey--prior-art-and-candidates).
Nothing here is decided; each row lists what has to be settled before it can be
built.

### To implement

| # | Item | Decisions needed |
|---|---|---|
| **B1** | **`minimal` submap** — a stripped binding set so an application can reclaim keys like `Alt-Tab` | What, if anything, survives inside it — pure passthrough, or a small survival set (exit, close window, workspace switch)? And **the leader**: `SUPER+grave` does not exist unshifted on AZERTY, and the physical key left of `1` is `²` (`twosuperior`), already bound to the special workspace. Needs another key or `code:49` |
| **B2** | **OSD overlays in Quickshell**, replacing avizo | Scope is smaller than it looks: **this host has 0 backlight devices and no `ddcutil`**, so a brightness OSD is inapplicable — volume and mute only (mic? caps-lock?). Replacing avizo is a three-part change: a new `multimedia` preset (today's commands *are* avizo's `volumectl`), `software.modules.avizo.enable = false`, and a Quickshell OSD driven by the Pipewire service `VolumeBluetooth.qml` already binds. Where does it render — focused monitor, or all? |
| **B3** | **Mods toggles** — DND, game mode, scheduler, idle inhibitor | **This is the same feature as B7.** Each is a toggle with a backend (`swaync-client -dnd`, `gamemoded`, the scx unit, an idle inhibitor) and the stubs already sit in the bar. Decide whether to build four bespoke widgets or one generic preset-driven toggle — the latter delivers B7 at the same time |
| ~~**B4**~~ | ~~Quickshell hot-reload after a rebuild~~ | **Done** — solved as a systemd user service with `X-Restart-Triggers` listing the generated config and the QML tree, so home-manager's sd-switch restarts it on activation. Also settles autostart (migration Phase 7) |

### Maybe — needs discussion

| # | Item | Decisions needed |
|---|---|---|
| **B5** | **Nested command menus** — a leader that opens a menu rather than firing an action (Omarchy's `Super+Ctrl+C` capture menu) | Submap-based or launcher-based (rofi already present)? Which menus are worth it, given the submap pill now makes modal state visible? |
| **B6** | **Control center** — one panel instead of three separate popovers | Does it replace the calendar / system / volume popovers or sit alongside them? `Popovers.qml` already enforces one-at-a-time, so the gain is layout and consistency, not mechanism |
| **B7** | **Script-backed custom widgets** — a generic widget driven by shell commands | The entry schema: read command, interval, format, click/toggle action, icon/colour per state. Whether state comes from polling (via `Sys.qml`) or events. See B3 — doing this well removes the need for bespoke toggle widgets |

## Plan

### Phase A — banding and rules ✅ **Done** (2026-09-12)

Introduce `wsFor(slot)` with `session` pinned to 1, so every id resolves to today's
value. Extend the workspaces preset additively. Generate all 81 `workspace_rule`
entries (S20).

**Verify**: the effective-config harness from the Lua migration reports an identical
call set apart from the 72 new workspace rules. Answer **V1** (where an unruled
workspace lands) and **V2** (Waybar's reaction) here, before anything depends on them.

### Phase B — the session submap ✅ **Done** (2026-09-12)

Add the `session` submap, the switch function, and the last-slot table. Sessions
become reachable. **Verify**: switch to session 2, confirm three empty workspaces
(11/12/13-ish per monitor), switch back, confirm the original windows and slots.

### Phase C — Quickshell session pill ✅ **Done** (2026-09-12)

Derive session and slot from the workspace id; render the current session plus the
open ones; keep the slot glyphs unchanged.

### Phase D — switch overlay

The centred name/number indicator. `hl.notification.create` first if it proves
sufficient, a Quickshell surface if not.

---

### Phase E — Refactor

A consolidation pass once the feature work settles. Known candidates, from
surveying what the sessions work actually left behind:

- **The session arithmetic is duplicated.** `Workspaces.qml` and `SessionPill.qml`
  each compute `session = ((id - 1) / band) + 1` independently. Extract a
  `Sessions.qml` singleton — the same treatment `Sys.qml` gave the system metrics,
  for the same reason: one source of truth, widgets stay pure views.
- **`homeManagerModules/hyprland/home.nix` has grown** a large bind-data section
  (`shortcutData`, `workspaceBindData`, `navigationBindData`, `mouseBindData`,
  `hyprData`). Consider moving the record construction into its own file, or
  further into Lua now that `lua/binds.lua` owns the API surface.
- **`lua/binds.lua`'s dispatcher chain is a long `if` ladder** (15 cases). A table
  lookup keyed by dispatcher name would read better and make the registry
  enumerable — useful for a future "what binds exist" view.
- **Preset boundaries**: `sessions` lives in the *workspaces* preset, submap
  presentation in the *shortcuts* preset, bar layout in the *quickshell* preset.
  Each was locally reasonable; check the set still coheres.
- **The shortcuts preset is long** — 19 hand-written entries plus 18 generated
  plus the submap map. Grouping, or splitting by concern, may help.
- **D7**: `wayland.windowManager.hyprland.package` is nixpkgs `0.56.2` while the
  session runs the flake input `0.56.0` — a second, unused Hyprland in the closure.
- **Dead stubs**: DND, REC, idle-inhibitor, GameMode, scheduler, notification count
  and the troll pill still render from layout data with no backend. Decide which
  become real and which are dropped.

**Verify**: the effective-config harness and the QML headless check report no
change — a refactor phase should move code, not behaviour.

### Phase F — Redesign

A pass over motion and visuals across the whole desktop, not just sessions. The
survey that motivates it:

- **Hyprland has no animation configuration at all.** The generated `hyprland.lua`
  contains **zero** `hl.animation` and `hl.curve` calls, so everything runs on
  compositor defaults. 0.55+ exposes animation leaves and both bezier and spring
  curves (`hl.curve("mySpring", { type = "spring", mass, stiffness, dampening })`).
- **Quickshell is almost entirely static**: only 2 of 19 QML files contain a
  `Behavior`, `Animation` or `Transition` — `SubmapPill` (a 120 ms colour fade) and
  `VolumeBtPanelView`. Popovers appear and vanish instantly; workspace pills snap.
- **A session switch moves all three monitors at once** with no visual bridge. This
  is the single largest motion event in the shell and currently has none.
- **Unbuilt design surfaces** from the Claude Design source: *System Module Hover*
  and *Wallpaper Pick Animation* were specified and never implemented.
- **Token consistency**: pill heights, radii and spacing are `Theme` constants but
  were tuned per widget as each was written; worth a consistency sweep.
- **Hover states** are ad hoc — some widgets dim on hover, some do nothing.

Scope note: this phase spans `homeManagerModules/hyprland` (compositor motion) and
`homeManagerModules/quickshell` (widget motion + visual consistency). It is
recorded here because this is the active plan, but it is not session-specific — see
also [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md) stages 4–6.

**Verify**: visual, so by relog and inspection. Keep animation parameters in the
presets rather than the widgets, so they are tunable without touching QML.

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
- [Omarchy — Hyprland configuration](https://deepwiki.com/basecamp/omarchy/4.1-hyprland-configuration) and [the minimal-submap discussion](https://github.com/omacom/omarchy/discussions/2675)
- [Omarchy hotkeys manual](https://learn.omacom.io/2/the-omarchy-manual/53/hotkeys)
- [ML4W keybindings (`default.lua`)](https://github.com/mylinuxforwork/dotfiles/blob/main/dotfiles/.config/hypr/conf/keybindings/default.lua) — including its AZERTY handling
- [Noctalia](https://github.com/noctalia-dev/noctalia) — a Quickshell shell owning every desktop surface
- `src/config/lua/objects/LuaMonitor.cpp` in the Hyprland source — `set_workspace` semantics
