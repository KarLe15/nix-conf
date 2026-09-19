# Mastodant-SysD: System Daemon

**Status**: Planned — architecture and decisions settled, implementation not started
**Date**: 2026-09-19
**Would affect**: `daemons/mast-sysd/` (new), `nixosModules/` (new),
`configurations/software/modules/`, `hosts/mastodant-1/`
**Related**: [SHELL-BACKEND.md](SHELL-BACKEND.md), [QUICKSHELL-SHELL.md](QUICKSHELL-SHELL.md),
[HYPRLAND_SESSIONS.md](HYPRLAND_SESSIONS.md) (B3/B7, B4)

---

## Provenance

Grows out of the `SHELL-BACKEND.md` proposal. That document's open decisions
(D1–D8) are settled here. The forward-reference in `Sys.qml`, `QUICKSHELL-SHELL.md`
and `quickshell/README.md` — "a future socket/DBus daemon can feed these same
properties (push instead of poll)" — is the ancestor of this design.

---

## Goal

One long-lived, compiled daemon owning the shell's *read* side (metrics, context,
processes, scx state) and *actuation* (scx switching first; toggle widgets later),
with a single source of truth for each piece of state it owns. Quickshell becomes a
client: it connects, receives pushes, and sends commands — no more per-process
shell one-shots.

Non-goals: audio, Bluetooth, Hyprland IPC, session logic, notifications, window
management — all stay with Quickshell-native services, Hyprland Lua, or swaync
(the scoping principle from `SHELL-BACKEND.md` holds unchanged).

### Decision: multimedia widget (MPRIS) — out of scope

A future media widget (play/pause/next/previous + metadata for Spotify, VLC,
mpv, and Firefox/Chromium-based browsers — Zen/Brave) will bind
**`Quickshell.Services.Mpris` directly** and stay entirely out of this daemon.
Rationale: all those players speak MPRIS on the *session* bus; Quickshell's
Mpris module is already event-driven with playback controls (`togglePlaying()`,
`next()`, `previous()`, `trackTitle`/`playbackState`/…); no privilege is
involved; a daemon (system or user) would only re-expose a native binding and
create a second place where media state lives. Same boundary as
Pipewire/Bluetooth. Lidarr is not a player (no MPRIS endpoint) — any future
"sync/downloading" indicator is a separate decision, at most a read-source
like ollama.

---

## Decisions (settles D1–D8 of SHELL-BACKEND.md)

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Transport | **Unix socket, newline-delimited JSON** (protocol v1) | Quickshell has **no generic DBus client module** (verified against the v0.1.0 and v0.3.1 type listings — only `DBusMenu` and baked-in services). `Quickshell.Io.Socket` + `SplitParser` is proven and event-driven. DBus is used *inside* the daemon (zbus), never exposed to QML. |
| D2 | Scope | **V1: metrics + context + top procs.** Phase 4 adds scx *state* (read), Phase 5 scx *actions* (write). Notifications stay out. | Honest first version; scx read-only is a natural bridge to the primary motivation. |
| D3 | Language | **Rust** | Meets all three hard requirements: compiled, memory-safe (borrow checker), thread-safe (`Send`/`Sync` at compile time). Zig fails memory-safety-by-construction. Ecosystem: tokio, zbus, serde, procfs; the whole scx ecosystem is Rust. |
| D4 | Packaging | **In-repo**, `daemons/mast-sysd/`, packaged by this flake | Versioned with the config it serves; one rebuild ships everything. |
| D5 | Lifecycle | **NixOS system service** (`WantedBy=multi-user.target`, `Type=notify`, `Restart=on-failure`) | sched_ext loading is root-only anyway; scx_loader is a system service; decoupled from shell rebuilds (B4). |
| D6 | Schema | Versioned `hello` frame; `Sys.qml` keeps its exact public surface | Swap is invisible to widgets; mismatch → degraded mode. |
| D7 | context.sh | **Replaced in Rust** (GameMode, ollama, docker, systemd probes ported) | One codebase, typed, testable, no silent failure. |
| D8 | Degraded mode | Last values + `connected: false` flag; QML reconnects with backoff (1 s→5 s) | No fallback to old pollers — two sources of truth is the thing this project exists to remove. |

Additional settled decisions:

| Decision | Choice |
|---|---|
| Daemon name / binary | `mast-sysd` (short, grep-friendly `mast-` prefix, unique in the repo). CLI: `mast-sysd status`, `mast-sysd get cpu|context|…` |
| Naming scheme | Uniform across binary, socket, group, unit, config, crate, module, options: `mast-sysd` everywhere (see Repo layout) |
| scx strategy | **Proxy scx_loader** (`org.scx.Loader` over the system bus, interface `org.scx.Loader`). scx_loader stays the owner of scheduler processes, so `scxctl` and any other client keep working. The daemon mirrors scx_loader state into its own snapshot → single source of truth *for the shell's view*. |
| scx DBus contract | Methods (from the shipped policy conf `share/dbus-1/system.d/org.scx.Loader.conf`): `StartScheduler`, `StartSchedulerWithArgs`, `SwitchScheduler`, `SwitchSchedulerWithArgs`, `StopScheduler`, `RestartScheduler`, `RestoreDefault` — mutations guarded by polkit action `org.scx.loader.manage-schedulers`; properties via standard `org.freedesktop.DBus.Properties`. Only root may own the name (hence the `AccessDenied` on manual runs). |
| Runtime model | Single process, single instance. One tokio task per source, one shared `Arc<RwLock<Snapshot>>`, broadcast to connected clients. |
| Access model | Socket `/run/mast-sysd/mast-sysd.sock`, mode `0660`, group `mast-sysd`. Peer uid/gid via `SO_PEERCRED` per connection. Group member = full read+write (single-user desktop; no separate ctl group / polkit). Quickshell is a full peer — it can command scx switches from Phase 5. |
| Session-bus access | Config-driven allowlist of users; daemon connects per-user to `/run/user/<uid>/bus` (GameMode probe is the only session-bus consumer today). Per-user connection task with reconnect/backoff; probes degrade when the session is gone. |

---

## Architecture

```
                        ┌────────────────────────────────────┐
  /proc, /sys (hwmon,   │  mast-sysd  (tokio, 1 proc)        │   /run/mast-sysd/
  DRM, /proc/net/dev) ──┤  metrics  sampler    (2 s)         │   mast-sysd.sock
                        │  context  probes     (5 s)         │   0660 group mast-sysd
  /run/user/<uid>/bus ──┤  procs    sampler    (5 s)         │   JSON-lines, protocol v1
  (GameMode, per-user)  │  SharedState  Arc<RwLock<Snapshot>>│
                        │  SocketServer  (broadcast+events)  ├────► Quickshell: Sys.qml
  ollama 127.0.0.1 ─────┤  CLI subs (status/get)             │      (same public surface)
  11434                 │                                    │
                        │  scx_loader proxy (zbus)           ├────► CLI clients / scripts
  /var/run/docker.sock ─┤  Phases 4–5                        │      (mast-sysd status)
                        └────────────────────────────────────┘
                                     │ zbus, system bus (Phase 4/5)
                                     ▼
                        scx_loader (org.scx.scx_loader) — still the owner of
                        scheduler processes; sysd mirrors state, forwards commands.
```

Design invariants:

- **One snapshot per tick** → internally consistent numbers, like today's shell one-shot.
- **Push + pull**: full snapshot on every tick and once on connect; discrete events
  (context switch, scx state change) pushed immediately — the "push instead of poll" win.
- **Per-source degradation**: every source reports Ok / Unavailable / Failed; a dead
  probe blanks only its own fields, never the whole snapshot (fixes `context.sh`'s
  silent-failure-by-design).
- **Ownership boundaries** (unchanged from `SHELL-BACKEND.md`): audio/BT/Hyprland stay
  Quickshell-native; the daemon never touches them.

Session-bus access details:

- A system daemon has no `DBUS_SESSION_BUS_ADDRESS` in its environment; the session
  bus is just a unix socket at `/run/user/<uid>/bus`, which root can connect to.
- Config lists allowed users (`session-users`); the module resolves each to
  `/run/user/<uid>/bus`. One zbus connection per configured user.
- `/run/user/<uid>/bus` disappears on logout → per-user connection task reconnects
  with backoff; that user's probes report "unavailable" meanwhile (same
  degraded-source model as everything else).
- GameMode's `ClientCount` property is world-readable on the session bus, so a plain
  connect suffices — no impersonation, same as running `busctl --user` today.

---

## Protocol (v1)

Newline-delimited JSON over the unix socket:

```json
{"v":1,"t":"hello","proto":1}
{"v":1,"t":"update","cpu":12,"cpuTemp":54,"memUsed":11.2,"memTotal":31.3,…}
{"v":1,"t":"event","kind":"context","value":"gaming"}
{"v":1,"t":"scx","sched":"rusty","state":"running"}
```

- Server sends `hello` (with protocol version) first on every connection; the QML
  side detects mismatch → degraded mode (D6/D8).
- Read ops: `get <field|all>` (reply: `update` frame). Write ops (Phase 5):
  `scx start|stop|switch <sched>`. Peer credentials checked per connection.
- Same protocol serves the CLI — desktop-free debugging and a CI-able test path.

---

## Repo layout

```
daemons/mast-sysd/
├── Cargo.toml
├── src/
│   ├── main.rs          # CLI + runtime wiring, sd-notify READY=1
│   ├── state.rs         # Snapshot, SharedState, broadcaster
│   ├── protocol.rs      # serde types, protocol versioning
│   ├── ipc.rs           # socket server, sessions, SO_PEERCRED
│   ├── config.rs        # TOML config (intervals, socket path, session users, scx allowlist)
│   └── sources/
│       ├── metrics.rs   # procfs/hwmon/DRM/net (replaces the shell one-shot in Sys.qml)
│       ├── context.rs   # GameMode (per-user session bus), ollama (HTTP), docker (sock), systemd
│       ├── procs.rs     # top-N CPU
│       └── scx.rs       # zbus proxy to scx_loader (Phase 4/5)
└── tests/               # parsers, socket integration, context-probe mappers

nixosModules/mast-sysd/
├── default.nix / nixos.nix   # package + mast-sysd.service, users.groups."mast-sysd",
│                             # config file generated from software.modules.mast-sysd.* options
└── README.md
```

NixOS module surface (follows repo conventions):

1. `flake.nix` — package from `daemons/mast-sysd` (`buildRustPackage`).
2. `configurations/software/modules/default.nix` — `software.modules.mast-sysd.enable`
   (+ intervals, session users, allowed scx schedulers).
3. `nixosModules/default.nix` — imports `./mast-sysd`.
4. `hosts/mastodant-1/services-configuration.nix` — enable it.
5. The module creates `users.groups."mast-sysd"` and adds the shell user to it.

QML side (Phase 2): `Sys.qml` keeps its name and full public property surface; its
three `Process` pollers are replaced by one `Quickshell.Io.Socket` + `SplitParser`
feeding the same properties. History buffers (`cpuHist` etc.) stay client-side.
Zero widget changes; `context.sh` deleted after Phase-3 parity.

Config file: `/etc/mast-sysd/config.toml`, generated by the NixOS module from
`software.modules.mast-sysd.*` options (sample intervals, socket path, session
users, allowed scx schedulers).

---

## Lifecycle

- `mast-sysd.service`: `After=systemd-modules-load.service` and, from Phase 4,
  `After=scx_loader.service` (the unit name nixpkgs' `services.scx-loader` module
  creates); `WantedBy=multi-user.target`; `Type=notify` (sd-notify crate — trivial
  in Rust); `Restart=on-failure`.
- Fully decoupled from user-session lifecycle and from rebuilds: Quickshell
  connects with backoff whenever the shell (re)starts; no ordering coupling
  with B4's open question.
- Kernel prerequisite: sched_ext requires kernel ≥ 6.12 with `CONFIG_SCHED_EXT`
  (verify in Phase 0 — `hosts/mastodant-1/kernel.nix` declares nothing about it yet).

---

## Roadmap

| Phase | Deliverable | Verification |
|---|---|---|
| **0. Spike** | ~~Verify kernel sched_ext support; scx_loader in nixpkgs; zbus probe of GameMode; scx_loader unit shape~~ | **Done** — see the verification log above |
| **1. Scaffold** | Crate, flake package, system unit, group + socket permissions, socket server + `hello`/version handshake, `status`/`get` CLI | `cargo test`; `nix build`; `mast-sysd status` |
| **2. Metrics** | `sources/metrics.rs` ported from the `Sys.qml` shell one-shot; `Sys.qml` socket-fed | headless `QT_QPA_PLATFORM=offscreen qs` harness (existing pattern), then on-target parity vs old numbers |
| **3. Context** | `sources/context.rs` — GameMode, ollama, docker, systemd probes; instant context events; delete `context.sh` after parity | probe-by-probe diff vs `context.sh` output on target |
| **4. scx read** | zbus proxy to scx_loader; `scx` frames; the `scx·rusty` stub pill (`screen-bars.nix:36`) shows real state | switch schedulers externally with `scxctl`; daemon + `scxctl` agree |
| **5. scx write** | forward start/stop/switch; shell toggle replaces the stub (B3/B7) | pill round-trip; scheduler actually switches |
| **6. Harden** | degraded-mode polish, tests, docs: `SHELL-BACKEND.md` status → implemented; `QUICKSHELL-SHELL.md` Sys section update | `nix flake check`, `cargo test`, headless QML checks |

Phases 2–3 are V1; 4–5 deliver sched_ext (the original motivation).

---

## Risks

| Risk | Mitigation |
|---|---|
| ~~scx_loader not packaged in nixpkgs~~ | **Resolved (Phase 0)**: `scx-loader` 1.1.2 is packaged, **with a NixOS module** (`services.scx-loader`: options `package`, `schedsPackages`, `config.default_sched`; installs the DBus policy + polkit; unit `scx_loader.service`). Note: `services.scx` cannot be enabled simultaneously (module assertion). |
| ~~Kernel lacks sched_ext / old kernel~~ | **Resolved (Phase 0)**: kernel `6.18.46` ≥ 6.12; BPF on; `/sys/kernel/sched_ext/` sysfs present (`state = disabled` is the idle state — `enabled` only while a BPF scheduler is loaded); `CONFIG_SCHED_EXT` no longer exists as a knob (built unconditionally). |

---

## Phase 0 verification log (2026-09-19)

| # | Check | Command | Result | Verdict |
|---|---|---|---|---|
| 1 | Kernel ≥ 6.12 | `uname -r` | `6.18.46` | ✓ |
| 1 | sched_ext built in | `ls /sys/kernel/sched_ext` + `cat /sys/kernel/sched_ext/state` | dir exists (`state`, `switch_all`, `nr_rejected`, …); `state = disabled` (idle) | ✓ |
| 1 | BPF prerequisites | `zgrep -E "CONFIG_BPF=|CONFIG_BPF_SYSCALL=" /proc/config.gz` | `CONFIG_BPF=y`, `CONFIG_BPF_SYSCALL=y` (no `CONFIG_SCHED_EXT` knob — built unconditionally) | ✓ |
| 2 | scx_loader packaged | `nix search nixpkgs scx` | `scx-loader` 1.1.2, `scx.full` 1.1.2, `scx.rustscheds` 1.1.2, `scx.cscheds` | ✓ |
| 2 | NixOS module | `cat $NIXPKGS/nixos/modules/services/scheduling/scx-loader.nix` | `services.scx-loader` module ships: unit `scx_loader.service`, DBus policy via `services.dbus.packages`, polkit, `/etc/scx_loader.toml` from `config.default_sched` | ✓ |
| 3 | GameMode probe (root → user bus) | `sudo busctl --address=unix:path=/run/user/$(id -u)/bus get-property …` | service absent → error (D-Bus-activated; `context.sh` handles the same absence today) → daemon maps absence to `Unavailable / ClientCount 0` | ✓ degraded path |
| 4 | DBus policy shape | `find …scx-loader-1.1.2 -path "*dbus*" -name "*.conf"` | `share/dbus-1/system.d/org.scx.Loader.conf` — explains the `AccessDenied` on manual runs; policy installed by the module | ✓ |
| Session-bus socket disappears on logout | per-user reconnect task; probes degrade individually |
| Docker stats sampling cost (~1 s) | sample only when container count > 0 (same as `context.sh`) |
| Schema drift QML ↔ daemon | versioned `hello` frame; one serde module owns the types |
| Second place for desktop state drift | scoping table from `SHELL-BACKEND.md` holds; daemon owns only metrics/context/procs/scx |

---

## Next step

Phase 1 scaffold: crate (`daemons/mast-sysd/`), flake package (`buildRustPackage`),
NixOS module (`nixosModules/mast-sysd/`), system unit, group + socket permissions,
socket server with `hello`/version handshake, `status`/`get` CLI.
