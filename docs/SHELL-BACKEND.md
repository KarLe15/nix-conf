# Enhancement Proposal: Shell Backend Service

> **Superseded by [MASTODANT-SYSD.md](MASTODANT-SYSD.md)** — the open decisions
> (D1–D8) below are settled there; this document remains as the original analysis.

**Status**: Draft — reconstructing a discussion that was never recorded
**Date**: 2026-09-12
**Would affect**: `homeManagerModules/quickshell/`, `configurations/software/`
**Related**: [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md), [HYPRLAND_SESSIONS.md](HYPRLAND_SESSIONS.md)

---

## Provenance

A backend daemon was discussed previously, but **the discussion was never written
down** — searching the repo, `TODO.md`, the memory files and the full git history
(`--all --grep`) finds no design, no decision, and no mention of Rust anywhere near
the shell.

What does exist is a forward-reference, repeated in three places and saying the same
thing:

> a future socket/DBus daemon can feed these same properties (push instead of poll)
> — `qml/Sys.qml:10`, `QUICKSHELL-SHELL.md:177`, `quickshell/README.md:122`

That is a note about why the `Sys.qml` boundary exists, not a design. This document
starts the design from scratch; fill in whatever the earlier conversation settled.

---

## What exists today

`qml/Sys.qml` is a process-global singleton and the **only** component that talks to
the system. Everything else is a pure view over it.

| Source | Mechanism | Interval |
|---|---|---|
| CPU, temps, GPU, RAM, VRAM, net | one shell one-shot over `/proc`, `/sys` | 2 s |
| Context (GameMode, ollama, docker, systemd) | `scripts/context.sh` | 5 s |
| Top processes | `ps` | 5 s |

Two timers, globally, regardless of how many bars are open — the singleton refactor
already removed the per-widget polling. **So "fewer pollers" is no longer the
argument for a daemon.**

Audio and Bluetooth already bypass `Sys` entirely: `VolumeBluetooth.qml` binds
Quickshell's native `Quickshell.Services.Pipewire` and `Quickshell.Bluetooth`
objects, which are event-driven and need no polling at all.

---

## The case for a backend

Honest version, now that the poller count is no longer the problem:

- **Push instead of poll.** A 2 s tick is visible latency on anything interactive
  (a toggle flipping, a container starting). Events are immediate.
- **State that survives a shell restart.** Quickshell must currently be restarted on
  every rebuild ([HYPRLAND_SESSIONS.md](HYPRLAND_SESSIONS.md) B4); anything it holds
  in memory is lost with it.
- **Somewhere to put actuation.** Toggles (DND, game mode, scheduler, idle inhibitor
  — B3/B7) need to both *read* and *change* state. Shelling out per click from QML
  works, but there is no single place that owns the result.
- **Error handling and testing.** `context.sh` fails silently by design; a typed
  service can report degraded sources and be unit-tested off the desktop.
- **Notifications** (S10) need a long-lived process anyway.

### The case against

- Quickshell's **native services are better than anything we would write** for
  Pipewire, Bluetooth and Hyprland IPC. A daemon must not duplicate them.
- It is another package, another unit, another failure mode, and a schema to keep in
  sync with the QML.
- The current implementation works. The gain is latency and structure, not function.

---

## Scoping principle

**The backend should own what Quickshell has no native binding for.** That line is
sharp and worth holding to:

| Concern | Owner | Why |
|---|---|---|
| Audio, Bluetooth | **Quickshell native** | `Services.Pipewire`, `Quickshell.Bluetooth`, event-driven |
| Workspaces, monitors, submap | **Quickshell native** | Hyprland IPC; sessions derive from workspace ids arithmetically |
| Session switching logic | **Hyprland Lua** | `lua/sessions.lua` holds it; `hyprctl repl` shares that state |
| CPU/GPU/RAM/net/temps | **Backend** | no native binding; currently a 2 s shell one-shot |
| Context (GameMode/ollama/docker/systemd) | **Backend** | currently `context.sh`, silent on failure |
| Toggles: DND, game mode, scheduler, idle inhibitor | **Backend** | needs read *and* write, plus a single source of truth |
| Notifications | **Backend** or swaync | see D2 |

---

## Open decisions

| # | Decision | Notes |
|---|---|---|
| **D1** | **Transport** — DBus, a unix socket, or both? | DBus gives introspection, signals and `busctl` debugging for free, and Quickshell can consume it. A raw socket is simpler and faster to write. Quickshell also has its own `qs ipc`, which is a third option in the other direction |
| **D2** | **Scope** — metrics only, or metrics + toggles + notifications? | Notifications are a large, separate problem (swaync exists and works). Starting with metrics + context keeps the first version honest |
| **D3** | **Language** — Rust was the instinct | Justified if the service is long-lived and typed. Worth stating *why* explicitly, since the alternative (keep `context.sh`, add a small poller) is nearly free |
| **D4** | **Packaging** — in-repo flake package, or its own repo? | In-repo keeps it versioned with the config it serves; a separate repo makes it reusable and independently testable |
| **D5** | **Lifecycle** — systemd user service, ordering, restart policy | Must interact cleanly with B4 (Quickshell's own service) and migration Phase 7 (autostart). Which starts first, and what happens on a rebuild? |
| **D6** | **Schema and versioning** — how does QML consume it? | A `Backend.qml` singleton mirroring today's `Sys.qml` surface would make the swap invisible to widgets. How is a schema mismatch detected? |
| **D7** | **Does it replace `scripts/context.sh` or wrap it?** | Replacing is cleaner; wrapping is a smaller first step and keeps the probe logic in one readable place |
| **D8** | **Degraded mode** — what does the bar show when the backend is down? | Blank pills, stale values with a marker, or a fallback to the current pollers? This decides whether the backend is a dependency or an optimisation |

---

## Sketch

If D6 goes the obvious way, widgets never learn the difference:

```qml
// Backend.qml — same property surface as today's Sys.qml
Singleton {
    property int  cpu: 0
    property int  cpuTemp: 0
    property string context: "standard"
    // …fed by the service instead of Process pollers
}
```

Every widget already reads `Sys.<prop>` and nothing else, so the migration is a
rename plus a transport — which is precisely what the singleton boundary was for.

---

## Risks

| Risk | Mitigation |
|---|---|
| **The backend becomes a second place where desktop state lives**, drifting from Hyprland's Lua and Quickshell's native services | Hold the scoping principle above; the backend owns only what has no native binding |
| **A schema mismatch after a rebuild** silently blanks the bar | Version the interface; D8 decides the degraded behaviour |
| **It replaces something that already works**, for latency alone | Start with metrics + context (D2) and measure before extending |
| **Another thing to restart on rebuild**, compounding B4 | Solve B4's lifecycle question once, for both units |
| **Scope creep into a full desktop environment** | Noctalia's boundary is instructive: a shell owns surfaces and services, not window management or compositor config |

---

## Next step

Settle **D2** (scope) and **D3** (language, and whether a service is warranted at
all) before anything else — they determine whether this is a weekend project or a
standing commitment. D1 and D6 follow from D2.
