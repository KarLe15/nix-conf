# quickshell-notify

The Quickshell notification server: a second shell instance that will own
`org.freedesktop.Notifications`, render the toasts and the notification centre, and
keep the history — while the bar instance becomes a client that knows only a count
and a presence state.

Design, decisions and phasing: **[docs/NOTIFICATIONS.md](../../docs/NOTIFICATIONS.md)**.

> **Status: phase 1 of 9 — scaffold.** The server receives and logs. It draws
> nothing, stores nothing, has no systemd unit, and does not touch the real session
> bus. **swaync is still your notification daemon** and stays that way until phase 7.

## Why a second instance

The same reason the lock screen is one (`homeManagerModules/quickshell-lock`): a
crash in bar code must not take it down. More specifically here — the bar unit
restarts on *every* rebuild, because Home Manager installs its config as a symlink
into the store and the file watcher never fires on an unchanged target. A
notification server sharing that fate would lose its history and drop whatever
arrived during the gap. Its own unit means bar edits leave it running.

## Running it

Enabling the module installs three commands and an inert config directory:

| Command | Goes to |
|---|---|
| `quickshell-notify-dev` | starts the instance on its own private bus |
| `quickshell-notify-send` | that instance |
| `notify-send` | **swaync** — the real bus |

Two terminals. In the first, leave the instance running; its log prints there:

```sh
quickshell-notify-dev
```

In the second, send it something:

```sh
quickshell-notify-send "karim mentioned you in #deploys" "check the rollout?" \
  --app-name=Slack --urgency=critical
```

`quickshell-notify-dev` wraps `dbus-run-session`, which gives a throwaway session bus
where `org.freedesktop.Notifications` is unowned. `WAYLAND_DISPLAY` survives into it,
so once there is something to draw it will draw on the real monitors — but nothing
your actual applications send reaches it, and swaync keeps working throughout.

That isolation is also why a plain `notify-send` cannot reach the dev instance: the
two are on different buses. `quickshell-notify-send` exists to bridge that — it reads
the instance's private bus address back out of `/proc/<pid>/environ` and forwards
every argument to `notify-send` unchanged. It refuses to send when no instance is
running, or when the instance it finds is on the real bus.

Plain `notify-send` still works and still goes to swaync, which is the quick way to
confirm swaync is unaffected.

> If you ever match the instance's pid by hand, match the command line **exactly**
> (`pgrep -f -x`). A substring `pgrep -f` also matches the `dbus-run-session` parent,
> which carries the command as its *arguments*, and any shell whose command line
> merely mentions the path — all of which live on the real bus. Sending to one of
> those hits swaync and looks like it worked.

Phase 1 output is one JSON line per notification on stdout, shaped like the history
record phase 3 will write:

```json
{"id":1,"app":"notify-send","desktopEntry":"","summary":"test","body":"body",
 "urgency":"Normal","transient":false,"resident":false,"actions":[],"hints":["urgency"]}
```

That log is also how each application's real `appName` and `summary` are discovered —
which is what the Focus `unless` patterns (D5) have to match.

## What is deliberately missing

| | Arrives in |
|---|---|
| A `Theme.qml` — nothing is drawn yet | phase 2, which needs the bar's theme generator factored out to be shared |
| Toasts | phase 2 |
| History (`.jsonl`) | phase 3 |
| Grouping | phase 4 |
| The socket the bar reads | phase 5 |
| The centre | phase 6 |
| Focus rules + capture suppression | phase 7 |
| A systemd unit, and swaync's retirement | phase 8 |

## Files

| Path | Role |
|---|---|
| `home.nix` | Config tree, the dev wrapper, `libnotify`. No unit — see the comment there |
| `qml/shell.qml` | `NotificationServer`, logging only |

One Quickshell detail worth keeping in mind when editing `shell.qml`: a notification
is **discarded as soon as the handler returns** unless `tracked` is set to true. An
empty `trackedNotifications` usually means that line went missing, not that nothing
arrived.
