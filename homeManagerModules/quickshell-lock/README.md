# quickshell-lock

The Stargate lock screen: the same gate room the SDDM greeter shows, as an
`ext-session-lock-v1` client written in QML.

Hyprlock cannot draw this. Version 0.9.6 has five widget types — `background`,
`image`, `label`, `shape`, `input-field` — no canvas and no per-keystroke hook.
Quickshell ships `WlSessionLock` and `PamContext`, so the lock reuses the
greeter's widgets from `qml/stargate/` and the gate actually dials.

## What it shows

Same three screens, same preset (`configurations/style/stargate/`), so the
machine looks the same cold or idle:

| Screen | Content |
|---|---|
| **gate** | clock, the Stargate, the dial sequence log |
| **dhd** | dial-home device, addresses, last login |
| **telemetry** | E2PZ modules, MALP board |

Two differences from the greeter, both because a lock is not a login:

- **No "Destination" picker** — the session is the one being unlocked.
- **No user switching** — the session belongs to whoever left it.

And one thing the greeter can never do: **the vortex is actually visible.** SDDM
closes its views the instant a login is accepted; here the lock holds for
`stargate.lock.unlockDelayMs` so the kawoosh plays.

### Typing works on any screen

The greeter's three screens are three QML engines and cannot share a keystroke.
The lock is one process, so `Auth` is a singleton every surface reads, and the
ambience screens forward keys into it (`Stage.qml`). Whichever surface the
compositor hands the keyboard to, the address lands in the same place.

## How locking happens

```
hypridle (idle timeout)          wleave / wlogout ("lock")
       └──── loginctl lock-session ────┘
                     │  logind Lock signal
       hypridle lock_cmd = stargate-lock
                     │
   qs -p ~/.config/quickshell-lock ipc call lock lock
                     │
         quickshell-lock.service (resident)
```

`defaults.lockscreen.command` is the single field all three callers read, so
repointing it moved every one of them at once.

The service is **resident and idle**, not spawned on demand: a windowless
quickshell instance stays alive, so the gate is already loaded and locks in one
frame instead of cold-starting into a blank compositor. It is also a **separate
instance from the bar** — a crash in bar code must not be able to take the lock
down, and vice versa.

`quickshell -c <name>` cannot select it: the CLI ignores config subdirectories
once `~/.config/quickshell/shell.qml` exists, which it does. Hence `-p`.

## Safety

`ext-session-lock` is deliberately unforgiving: **if the client dies while
locked, the compositor stays blocked and there is no password prompt.** Three
things exist because of that.

1. **`Restart=always`** on the unit — load-bearing, not tidiness.
2. **Re-lock on start.** `shell.qml` reads logind's `LockedHint` and locks
   immediately if it is set, so a restart while locked — a rebuild over SSH, or
   the `X-Restart-Triggers` firing — comes back to a prompt rather than a blank
   screen. The lock keeps that hint honest via `SetLockedHint`.

   Note it is `SetLockedHint`, **not** `loginctl lock-session`: that sends the
   Lock *signal*, which hypridle answers by running `lock_cmd` — which is what
   got us here. The hint is the fact; the signal is the request.
3. **hyprlock stays installed.** Swap the two `lockscreen` blocks in
   `configurations/software/defaults/presets/mastodant-1.nix` and rebuild.

If it ever does wedge, from a TTY:

```fish
set -x XDG_RUNTIME_DIR /run/user/1000
set -x WAYLAND_DISPLAY wayland-1
qs -p ~/.config/quickshell-lock
```

A new client may bind while the session is locked — that is the intended path.

## Layout

```
homeManagerModules/quickshell-lock/
├── home.nix              # merges qml/stargate + ./qml, generates the singletons, the unit
└── qml/
    ├── shell.qml         # IpcHandler · WlSessionLock · LockedHint check · preview windows
    ├── Stage.qml         # connector -> screen role, design-space scaling, key forwarding
    ├── Auth/Auth.qml     # the state machine: PamContext, caps LEDs, unlock timing
    ├── screens/GateScreen.qml
    └── widgets/PowerActions.qml
```

Everything else — `Gate`, `Chevron`, `Dhd`, `Zpm`, the lists, the bars — comes
from `qml/stargate/`, shared verbatim with the greeter.

`Theme.qml` and `Config.qml` are generated on rebuild by
`qml/stargate/generate.nix`, the same renderer the greeter uses.

### Caps lock

Quickshell exposes no keyboard LED state, so `Auth` polls
`stargate.lock.capsLedGlob` (`/sys/class/leds/*::capslock/brightness`) every
500 ms **while locked only**, and shows nothing if the glob matches no files — a
wrong caps indicator is worse than none.

## Testing it without locking yourself out

Everything below runs in a **nested headless compositor**, so your real session is
never touched:

```fish
nix shell nixpkgs#sway nixpkgs#grim
env -u WAYLAND_DISPLAY WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=3 \
    WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman sway -c /dev/null &

set tree (nix build --no-link --print-out-paths \
  .#homeConfigurations…)   # or just use ~/.config/quickshell-lock
env WAYLAND_DISPLAY=wayland-2 qs -p $tree &
env WAYLAND_DISPLAY=wayland-2 qs -p $tree ipc call lock lock
env WAYLAND_DISPLAY=wayland-2 grim -o HEADLESS-1 /tmp/gate.png
```

Remap `Config.screens` in a writable copy to `HEADLESS-1/2/3` to exercise the
real connector routing. Note the nested instance shares your **real logind
session**, so no-op the `busctl` call in `shell.qml` in that copy or it will set
your session's `LockedHint`.

For design work without any lock at all, `STARGATE_PREVIEW=gate|dhd|telemetry`
renders the screens in ordinary layer-shell windows, and
`STARGATE_PREVIEW_STATE=live|dialing|error|capslock|success` holds the gate in
one state.

```fish
journalctl --user -u quickshell-lock -b   # QML errors and the PAM conversation
```
