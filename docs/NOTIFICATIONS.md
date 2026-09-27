# Notifications: Quickshell Notification Server

**Status**: In progress — decisions settled; **phase 1 of 8 (scaffold) done**, swaync still serving
**Date**: 2026-09-27
**Would affect**: `homeManagerModules/quickshell-notify/` (**added**, phase 1),
`homeManagerModules/quickshell/` (count pill, `Presence.qml`),
`configurations/software/modules/`, `configurations/style/quickshell/`,
`homeManagerModules/swaync/` (disabled)
**Related**: [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md) (stage 4),
[MASTODANT-SYSD.md](MASTODANT-SYSD.md) (the client/server pattern this mirrors),
[SHELL-BACKEND.md](SHELL-BACKEND.md) (the scoping principle)

---

## Provenance

Stage 4 of the [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md) roadmap, the last
outstanding item of stage 7 ("swaync outstanding"), and the S10 forward-reference in
[SHELL-BACKEND.md](SHELL-BACKEND.md). `qml/Presence.qml:13` already names the thing
this unblocks:

> swaync cannot filter per application, so a Focus that "mutes chat & mail" would be
> a lie. Real Focus rules arrive with the Quickshell notification centre that
> replaces swaync.

[MASTODANT-SYSD.md](MASTODANT-SYSD.md) lists notifications as an explicit non-goal of
`mast-sysd`, and that holds — see D1.

---

## Goal

Replace swaync with a **second Quickshell instance** that owns
`org.freedesktop.Notifications`, renders the toasts and the notification centre, and
persists history. The bar becomes a client that knows only a count and a presence
state.

Non-goals: the bar does not see notification content; `mast-sysd` gains nothing;
no new compiled daemon.

---

## Decisions

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Daemon, or Quickshell-native? | **Quickshell-native, in its own instance.** No new compiled daemon. | Quickshell ships a complete freedesktop server (see Verification 1). `SHELL-BACKEND.md`'s scoping principle — *"the backend should own what Quickshell has no native binding for"* — excludes it. And `mast-sysd` is a **system** service (root, `multi-user.target`, for sched_ext); notifications are *session*-scoped D-Bus. A root daemon proxying session buses for a UI is the wrong side of the privilege boundary. |
| D2 | Durability | **Both halves: separate process (restart gap) + daily NDJSON files (history).** | They solve different failures — see the table below. Storage is JSON-lines rather than SQLite because the history is destined for an **ETL to a NAS** (ElasticSearch or similar) for analysis: one self-contained record per line ships without reshaping, and completed daily files are immutable ETL input. SQLite was verified working (Verification 4) and rejected on shape, not capability. |
| D3 | Cutover | **Build on a private bus; flag day last.** Develop the whole thing under `dbus-run-session`, where the notification name is unowned and `WAYLAND_DISPLAY` still works — toasts render on the real screens while swaync keeps serving the real bus. `software.modules.swaync.enable = false` lands in the same rebuild that first enables the `quickshell-notify` unit, once toasts, centre and history all work. | Only one process may own `org.freedesktop.Notifications` per session bus, so the two cannot coexist on the real one (Verification 8). Claiming it early would mean living without a working notification system for the length of the build, where every bug is a notification you never saw. |
| D4 | Rollback | Keep the swaync module **present but disabled** until the centre is solid. Deep clean of unused modules is a later, separate pass. | A broken server means *no notifications at all*, silently. Re-enabling must be a one-line revert. Safe to leave installed: swaync ships **no D-Bus activation file** (Verification 9), so a disabled unit cannot be auto-started into a name fight with the new server. |
| D5 | Presence / Focus | **Three distinct behaviours** — Available: all toasts; Focus: `focusMutes` denylist with per-app regex `unless` exceptions; DND: silence except `urgency = critical`. The shell ships the **matcher**; `focusMutes` starts empty and the rules are written by hand. In every state the notification still reaches the centre and the history. `Presence.qml` stops shelling to `swaync-client` and reads the new instance. See *Presence rules* below. | A native server sees `appName`/`desktopEntry`/`summary` before anything is drawn, so Focus can suppress the *interruption* without suppressing the *record*. Today Focus and DND are the same `swaync-client -dn` with different labels. |
| D6 | Advertised capabilities | **Each flag is flipped in the same commit that implements its rendering** — image at phase 2, persistence at 3, actions/actionIcons/inlineReply at 5. Full set by phase 7; the three markup flags stay off. See *Advertised capabilities* below. | Quickshell defaults nearly everything to false, so this is not just about persistence: `actionsSupported: false` means apps never send actions and the centre has nothing to render. Each flag is a promise to senders, and breaking one fails silently — the app believes it sent a reply box and nothing is drawn. |

### Why both halves of D2

| | Restart gap (rebuild) | History across reboot / crash |
|---|---|---|
| Separate process only | solved — the notify unit does not restart when bar QML changes | lost |
| NDJSON only | ~1 s of notifications lost per rebuild | solved |
| **Both** | **solved** | **solved** |

### History storage (D2)

Daily JSON-lines files under `~/.local/share/quickshell-notify/`:

```
notifications-2026-09-27.jsonl
notifications-2026-09-26.jsonl
```

One self-contained record per line. Today's file is rewritten whole on each arrival
— `Quickshell.Io.FileView` has no append, only `setText`/`setData` — which is cheap
because a day's volume is bounded (a few hundred lines, tens of KB). `atomicWrites`
is on by default (temp file + rename), so a reader never sees a torn file. Rotating
daily keeps that rewrite bounded *and* leaves every completed file immutable, which
is what makes it good ETL input: ship it and delete it.

Record shape (v1):

```json
{"ts":"2026-09-27T19:42:11.204Z","id":417,"app":"Slack","desktopEntry":"slack",
 "summary":"karim mentioned you","urgency":"normal","transient":false,
 "actions":["default","reply"],"toastShown":false,"suppressedBy":"focus",
 "closeReason":"dismissed","closedAt":"2026-09-27T19:44:02.118Z"}
```

`toastShown` / `suppressedBy` are worth capturing at write time and unrecoverable
later: they are what tells you whether the D5 Focus rules are actually right.

`body` capture is a preset toggle (`historyIncludeBody`, default off). Bodies carry
message contents, and this file is destined for a searchable store — that should be a
deliberate choice rather than a side effect.

Downstream ETL (NAS → ElasticSearch or similar) is **out of scope for this document**
and out of the shell entirely: it reads completed `.jsonl` files and nothing in the
shell needs to know it exists. Note for whoever writes it: `atomicWrites` replaces the
file by rename, so today's file changes inode on every write — a naive `tail -f`
breaks. Ship completed days, not the live one.

### Development on a private bus (D3)

`dbus-run-session` starts a throwaway session bus on which
`org.freedesktop.Notifications` is unowned, while leaving `WAYLAND_DISPLAY` intact:

```
$ dbus-run-session -- sh -c 'busctl --user call org.freedesktop.DBus \
      /org/freedesktop/DBus org.freedesktop.DBus GetNameOwner s \
      org.freedesktop.Notifications; echo "wayland: $WAYLAND_DISPLAY"'
Call failed: ... no such name
wayland: wayland-1
```

So the instance under development claims the name on *its* bus, renders toasts on the
real monitors, and never touches the one swaync is serving. A dev wrapper —
`quickshell-notify-dev`, the same `writeShellScriptBin` shape as `stargate-lock`
(`quickshell-lock/home.nix:39`) — is:

```sh
exec dbus-run-session -- quickshell -p "$HOME/.config/quickshell-notify"
```

Two things keep the dev instance from being mistaken for the real one:

- **Socket path.** The dev run serves `quickshell-notify-dev.sock`, not
  `quickshell-notify.sock`, so the bar cannot silently attach to a scratch instance
  and report test counts.
- **History path.** Dev writes under `…/quickshell-notify-dev/`, so experiments never
  land in the archive destined for the NAS.

`libnotify` (`notify-send`) is needed as a dev dependency — it is **not** currently
installed. `busctl call org.freedesktop.Notifications … Notify` works without it, but
the signature (`susssasa{sv}i`) makes it painful for repeated use.

The wrapper and both `-dev` paths are scaffolding: they are deleted at the flag day,
not carried.

### Presence rules (D5)

Three states, three genuinely different behaviours — where today Focus and DND are
the same `swaync-client -dn` with different labels and ring colours.

| State | Toast shown for |
|---|---|
| **Available** | everything |
| **Focus** | everything except apps in `focusMutes`, minus each app's own `unless` exceptions |
| **DND** | nothing except `urgency = critical` (system-sourced alarms) |

**In all three states the notification still lands in the centre and in the history.**
Presence suppresses the *interruption*, never the *record* — which is what makes
Focus safe to leave on.

```nix
presence = {
  focusMutes = [
    { app = "Slack";       unless = [ "#deploys" "#incidents" ]; }
    { app = "discord";     unless = [ ]; }
    { app = "thunderbird"; unless = [ ]; }
  ];
};
```

`app` matches `appName` or `desktopEntry`. `unless` is a list of patterns tested
against `summary` and `body`; any match re-admits the notification as a toast.

**Constraint: there is no channel field.** The spec gives a server only `appName`,
`desktopEntry`, `summary`, `body`, `urgency`, `category` and a free-form `hints` map.
Slack carries the channel inside the **summary text**, so a per-channel rule is a
pattern match on display text the app can change in any update. Accepted as the only
available mechanism, not mistaken for a stable interface — when a pattern stops
matching, the failure is "Focus got quieter", not a crash.

**The mechanism ships; the patterns do not.** Phase 6 delivers the matcher and an
empty `focusMutes`, and the rules are filled in by hand afterwards — they are personal
and they change. Nothing in the shell needs to know what is in the list.

If a pattern ever fails to match, the payload an application really sends can be read
off the live bus without touching the shell:

```sh
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'"
```

`toastShown` and `suppressedBy` go into every history record (see *History storage*)
precisely so these rules can be checked against what actually happened.

### Advertised capabilities (D6)

Quickshell's `NotificationServer` advertises almost nothing by default. These go out
over `GetCapabilities()`, and well-behaved applications use them to decide what to
send — so `actionsSupported: false` means apps do not send actions **at all**, and a
centre built to render action buttons would have nothing to draw.

| Capability | Quickshell default | Enabled in phase | Promise it makes |
|---|---|---|---|
| `bodySupported` | **true** | — | body text is displayed |
| `imageSupported` | false | 2 (toasts) | `image`/`appIcon` is rendered |
| `persistenceSupported` | false | 3 (history) | it survives leaving the screen |
| `actionsSupported` | false | 5 (centre) | action buttons exist and `invoke()` works |
| `actionIconsSupported` | false | 5 (centre) | action icons are drawn, not just labels |
| `inlineReplySupported` | false | 5 (centre) | a reply field exists and `sendInlineReply()` works |
| `bodyMarkupSupported` | false | — (see below) | markup is parsed rather than shown raw |
| `bodyHyperlinksSupported` | false | — | links are clickable |
| `bodyImagesSupported` | false | — | inline `<img>` in the body renders |

**Rule: a flag is flipped in the same commit that implements its rendering.** Never
before. Advertising a capability you do not render fails *silently* — the application
believes it sent a reply box, nothing is drawn, and nothing reports the mismatch.

By phase 7 the first six rows are all true. The three markup rows stay false unless a
real payload justifies them.

**Markup gotcha, independent of the flags.** Applications send Pango markup whether or
not it is advertised, and QML `Text` parses markup by default — so an unstyled body
silently renders `<b>` as bold and, worse, swallows anything that looks like a tag.
Every body and summary `Text` needs `textFormat: Text.PlainText` unless
`bodyMarkupSupported` is deliberately turned on.

### Why hot reload is not an option

An earlier sketch proposed dropping the QML from `X-Restart-Triggers` and letting
Quickshell's file watcher hot-reload instead, keeping the process (and the bus name,
and `keepOnReload` state) alive across rebuilds. **This does not work**, and
`homeManagerModules/quickshell-lock/home.nix:56` already records why:

> Home Manager installs the config as a symlink into the store, whose target never
> changes, so the file watcher never fires and only a changed unit text gets the new
> generation running.

Quickshell watches the resolved store path, which is immutable; re-pointing the
symlink produces no inotify event on it. The restart is **required**, not
self-inflicted — which is precisely why the server has to live in a unit with its own
restart cadence.

`keepOnReload` is also narrower than it sounds: it re-emits tracked notifications
across a QML **reload**, within one process. It does nothing across a process restart.

---

## Architecture

Two Quickshell instances, the pattern `quickshell-lock` already established in this
repo ("a crash in bar code must not be able to take the lock down, and vice versa" —
`quickshell-lock/home.nix:49`).

```
                    session bus: org.freedesktop.Notifications
                                        │
                          ┌─────────────▼──────────────┐
                          │  quickshell-notify         │  ← owns the bus name
                          │  ---------------------     │
                          │  NotificationServer        │
                          │  toast stack               │
                          │  notification centre       │
                          │  SQLite history            │
                          │  DND / Focus state         │
                          └─────────┬──────────────────┘
                                    │  unix socket, NDJSON
                                    │  push: { count, dnd, presence }
                          ┌─────────▼──────────────────┐
                          │  quickshell  (the bar)     │
                          │  ---------------------     │
                          │  count pill (MirrorPill)   │
                          │  avatar ring (Presence)    │
                          └────────────────────────────┘
```

**What each owns.** The notify instance owns every notification object, the history,
and the presence state. The bar owns nothing here — it renders a number and a colour.
Notification *content* never crosses the socket.

**Restart cadence** is the point of the split. The notify unit's
`X-Restart-Triggers` name only its own QML and `Theme.qml` — **not** `Config.qml`,
which carries the bar layout it does not care about. Editing a bar widget then
restarts the bar and leaves the notification server untouched.

### Known friction: `Popovers` is per-process

`qml/Popovers.qml` coordinates one-popover-at-a-time and the `HyprlandFocusGrab`
(which grabs the open popover *plus every registered bar*). Both are process-local
and **cannot span the two instances**. A centre living in the notify process will not
participate in the bar's popover exclusivity, and its click-outside dismissal needs
its own grab.

Accepted: a full-height drawer is a different interaction class from a bar popover,
and the lock screen already takes exclusive input without consulting `Popovers`. If
the centre later needs to close when a bar popover opens, that is one more socket
frame, not a redesign.

---

## Protocol (v1)

Unix socket, newline-delimited JSON — the same transport
[MASTODANT-SYSD.md](MASTODANT-SYSD.md) D1 settled on, for the same reason
(`Quickshell.Io.Socket` + `SplitParser` is proven and event-driven; Quickshell has no
generic D-Bus client module).

Socket path: `$XDG_RUNTIME_DIR/quickshell-notify.sock`, served by
`Quickshell.Io.SocketServer` in the notify instance.

**Server → bar** (push on every change):

```json
{"v":1,"type":"hello","protocol":1}
{"type":"state","count":3,"dnd":false,"presence":"focus"}
```

**Bar → server** (on the same socket):

```json
{"type":"setPresence","state":"dnd"}
{"type":"openCentre"}
```

**CLI / keybind entry** is free alongside this: an `IpcHandler` in the notify
instance gives `quickshell -p ~/.config/quickshell-notify ipc call presence set dnd`,
exactly how `stargate-lock` drives the lock instance today
(`quickshell-lock/home.nix:39`). That makes a Hyprland keybind for DND a
shortcuts-preset entry rather than new code.

**Degraded mode**: the bar keeps its last values and flags `connected: false`,
reconnecting with backoff — the `Presence.qml` reconnect `Timer` already does this
shape for the swaync subscription and carries over unchanged.

---

## Repo layout

```
homeManagerModules/quickshell-notify/
├── default.nix                 # imports home.nix
├── home.nix                    # config tree, unit, Theme/Config generation
├── README.md
└── qml/
    ├── shell.qml               # NotificationServer + IpcHandler + SocketServer
    ├── Notifications.qml       # singleton — tracked list, history, DND/Focus rules
    ├── History.qml             # singleton — daily NDJSON read/write (FileView)
    ├── Server.qml              # singleton — socket server, state frames
    └── widgets/
        ├── Toast.qml           # one notification popup
        ├── ToastStack.qml      # the stack, per-monitor
        ├── Centre.qml          # the drawer
        └── CentreRow.qml       # one row in the centre (actions, inline reply)
```

Mirrors `quickshell-lock/`: a `pkgs.runCommand` merges the QML tree with the
generated `Theme.qml`, installed via `xdg.configFile."quickshell-notify".source`.

Preset additions in `configurations/style/quickshell/presets/screen-bars.nix`:

```nix
notifications = {
  monitor    = "code";        # monitor ROLE the toasts render on (open question)
  placement  = "top-right";
  holdMs     = 5000;          # urgency-normal; critical never auto-expires
  maxVisible = 3;

  historyDays        = 30;    # daily .jsonl files kept before deletion
  historyIncludeBody = false; # bodies carry message contents — opt in (D2)

  ## D5 — Focus denylist with per-app exceptions. `unless` patterns are tested
  ## against summary and body; any match re-admits the toast.
  ## Ships empty; rules are written by hand. Shape:
  ##   { app = "Slack"; unless = [ "#deploys" "#incidents" ]; }
  presence.focusMutes = [ ];
};
```

---

## Lifecycle

`systemd.user.services.quickshell-notify`, modelled on `quickshell-lock`:

| Field | Value | Why |
|---|---|---|
| `PartOf` / `After` | `graphical-session.target` | Session-scoped, like the bar |
| `ConditionEnvironment` | `WAYLAND_DISPLAY` | Same guard as the bar and lock |
| `X-Restart-Triggers` | own `qml/` + `themeQml` **only** | Bar edits must not restart the server (the whole point of D1) |
| `Restart` | `always`, `RestartSec = 1` | While it is down, notifications are silently dropped — nothing queues them |
| `KillMode` | `mixed` | Same as the bar; it launches nothing long-lived |

Ordering against swaync is not needed — D3 makes them mutually exclusive.

---

## Widget surface

Three separable pieces, in build order:

| # | Piece | Lives in | Notes |
|---|---|---|---|
| 1 | **Toast stack** | notify | Per-notification popup. The OSD components (`OsdCard`, `OsdNotch`) already solve timed overlays with `holdMs`/`fadeMs` and are the closest prior art. Critical urgency must not auto-expire. |
| 2 | **Count pill** | bar | `{ w = "notifications" }` is a `MirrorPill` today reading `Presence.count`. It keeps working — only its source changes from the swaync subscription to the socket. |
| 3 | **Centre** | notify | The history list: per-notification actions (`invoke()`), inline reply (`sendInlineReply()`), dismiss, clear-all, DND toggle. The real work. |

The avatar control centre's presence switch becomes real under D5: a preset list of
app ids, one rule check before a toast is drawn. Everything still lands in the centre.

---

## Roadmap

Phases 1–6 run on a **private bus** (D3): swaync keeps serving real notifications
throughout, and nothing user-visible changes until phase 7.

| Phase | Deliverable | Verification |
|---|---|---|
| **0. Spike** | ~~Server API surface; multi-instance; NDJSON write shape; push transport; private-bus dev path~~ | **Done** — see the verification log below |
| **1. Scaffold** | ~~Module, config tree, `quickshell-notify-dev` wrapper, `NotificationServer` logging received notifications. No unit, no real-bus claim~~ | **Done (2026-09-27)** — ran under `dbus-run-session`; two `notify-send` calls logged in the D2 record shape; real bus still owned by swaync afterwards |
| **2. Toasts** | Toast stack, per-monitor, urgency-aware (critical never auto-expires); `imageSupported` on | send one of each urgency; critical stays until dismissed |
| **3. History** | Daily `.jsonl` via `FileView`, write on arrival, read today + yesterday on start, `historyDays` trim; `persistenceSupported` on | restart the dev instance mid-session; history survives; read the file by hand |
| **4. Socket** | `SocketServer` + state frames; bar client written against the **dev** socket | two instances agree on the count; kill the dev instance → bar degrades, does not hang |
| **5. Centre** | The drawer: actions (`invoke()`), inline reply, dismiss, clear-all, DND toggle; `actionsSupported`, `actionIconsSupported`, `inlineReplySupported` on | round-trip an action against an app that sends them |
| **6. Focus (D5)** | The matcher — app denylist plus per-app `unless` patterns — shipping with an **empty** `focusMutes`; `toastShown`/`suppressedBy` recorded | a hand-written rule suppresses its app; an `unless` match re-admits it; both land in the history | a muted app produces no toast but a centre row and a history line |
| **7. Flag day** | Unit lands, swaync disabled, bar swaps off `swaync-client`, dev wrapper and `-dev` paths deleted | `notify-send` on the real bus renders; `busctl … GetNameOwner` points at the new instance; swaync gone from `systemctl --user list-units` |
| **8. Harden** | Docs: this file → implemented; `QUICKSHELL-SHELL.md` stages 4 + 7 | headless QML checks, on-target soak |

Phase 7 is the only one with a risk window, and D4 is its undo.

---

## Risks

| Risk | Mitigation |
|---|---|
| Server breaks → **silent** total notification loss | D4: swaync module stays present-but-disabled; re-enable is one line. D3 keeps the build entirely off the real bus until phase 7, so this is exposure of one phase, not eight. |
| The notify unit is down → notifications dropped, nothing queues them | `Restart=always`, `RestartSec=1`. The gap is the same one swaync has; it is not made worse. |
| Schema drift bar ↔ notify | Versioned `hello` frame (mast-sysd D6 pattern); mismatch → bar degrades to `connected: false` rather than mis-rendering. |
| Whole-file rewrite per notification (FileView has no append) | Daily rotation bounds it to one day of records. If volume ever makes this hurt, a `Process` append shell-out or SQLite (Verification 4) are both open. |
| Two QML runtimes' memory cost | Measure at phase 2. The lock instance already pays this and is resident all session. |
| Centre cannot join the bar's popover exclusivity | Accepted — see *Known friction*. One socket frame fixes it later if it matters. |

---

## Phase 0 verification log (2026-09-27)

| # | Check | How | Result | Verdict |
|---|---|---|---|---|
| 1 | Quickshell has a full notification server | Read `src/services/notifications/{qml,notification,server}.hpp` of the 0.3.1 source | `urgency`, `actions` + `actionIcons`, `inlineReply` (`sendInlineReply()`), `image`/`appIcon`, `desktopEntry`, `transient`, `resident`, `expireTimeout`, raw `hints`, `trackedNotifications` model, `dismiss()`/`expire()`/`invoke()` | ✓ superset of the swaync features in use |
| 2 | `keepOnReload` scope | Same headers | *"re-emitted when quickshell **reloads**"* — QML reload, one process. Nothing across a restart | ✓ does not solve durability |
| 3 | Multiple instances run concurrently | `quickshell list` against the live bar; headless instances run alongside it all session | Instances keyed by config path + instance id; no single-instance lock. `quickshell-lock` already ships a second instance | ✓ |
| 4 | SQLite from QML | `QtQuick.LocalStorage` inside an offscreen instance: create table, insert, count | `SQLITE-OK rows=1`; driver present (`qtbase …/sqldrivers/libqsqlite.so`) | ✓ available, **not used** — D2 chose NDJSON on ETL grounds. Recorded so the option stays open |
| 5 | `FileView` write API | `src/io/fileview.hpp` | `setText`/`setData` only — **no append**; `atomicWrites` defaults on (temp + rename) | ✓ shapes D2 into daily rotated files |
| 6 | Push transport | `src/io/socket.hpp`, `src/io/ipchandler.hpp` | `SocketServer` + `Socket` give push; `IpcHandler` is call/response only (`qs ipc call`) — right for CLI, wrong for a live count | ✓ socket for state, IpcHandler for keybinds |
| 7 | Hot reload as a durability route | `quickshell-lock/home.nix:56` | Home Manager symlinks into the store; the watched target never changes, so the watcher never fires. Restart is required | ✗ ruled out — see D2 |
| 8 | Private-bus development path | `dbus-run-session` + `busctl … GetNameOwner … org.freedesktop.Notifications` | name unowned on the private bus; `WAYLAND_DISPLAY=wayland-1` survives into it | ✓ enables D3 — build with swaync still running |
| 9 | Can a disabled swaync be auto-started? | `grep -rl org.freedesktop.Notifications` over the session D-Bus service dirs; `systemctl --user list-unit-files swaync*` | no activation file anywhere claims the name; swaync is a plain user unit (`swaync.service enabled`) | ✓ D4 is safe — disabling the module removes the unit, nothing reactivates it |
| 10 | Capability flags gate what senders transmit | phase 1 run: `notify-send … -A reply=Reply` against the scaffold | notify-send printed *"Actions are not supported by this notifications server"* and the payload arrived with `actions: []` | ✓ D6 confirmed live — an unadvertised capability is dropped by the sender, silently |

---

## Open questions

- **Which monitor role** do toasts render on? The OSD preset picks `terminal`; the
  notifications mockup may disagree. Needs the design surface checked.
- **Critical urgency** — never auto-expire is assumed above. Confirm against the
  `Notifications` mockup.
- **Centre placement** — a full-height drawer (roadmap stage 6's side drawer) or a
  right-anchored panel? Affects nothing structural; both live in the notify instance.

---

## Next step

**Phase 1 scaffold:** `homeManagerModules/quickshell-notify/` modelled on
`quickshell-lock/`, the `quickshell-notify-dev` wrapper, and a `NotificationServer`
that logs `trackedNotifications`. No unit and no real-bus claim yet — swaync keeps
serving the real bus through phase 6, and nothing user-visible changes until D3's
flag day at phase 7.

`libnotify` (`notify-send`) is not installed and is needed to drive the dev instance.
