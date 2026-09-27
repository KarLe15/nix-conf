# sddm-stargate

The SDDM greeter theme for this machine: the SGC gate room, spread over the three
monitors. Nix side of the **Login Manager Stargate** design.

This module only supplies and selects the theme — `services.displayManager.sddm.enable`
is set separately, in `hosts/mastodant-1/services-configuration.nix`.

## The three screens

| Screen | Connector | What it is |
|---|---|---|
| **gate** | `HDMI-A-2` (3440×1440) | The greeter. Clock, the Stargate, the dial sequence log, the session picker. |
| **dhd** | `DP-3` (1920×1080, left) | Dial-home device idling, saved gate addresses, last login. Display only. |
| **telemetry** | `DP-1` (1920×1080, right) | Three E2PZ modules and the MALP environment board. Display only. |

Connector → screen comes from `configurations/style/sddm/presets/stargate.nix`, so
moving the greeter to another monitor is a one-line change.

### Dialling

Typing the password dials the gate. Each character **codes a chevron** and turns the
inner ring 40°; `↵` locks the seventh and submits; `esc` cancels. A rejected password
cancels the dial and turns every engaged chevron red, with the reason on the line under
the field — PAM's own wording when it gives one, otherwise "mot de passe incorrect".

Typing stops lighting chevrons at `gate.maxPreLock` (six). That cap is deliberate: the
chevrons are visible from across the room, and without it they would report the
password's length. With it, anything from six characters up looks the same.

## Why the two other screens are autonomous

SDDM 0.21 creates **one `QQuickView` per monitor, each with its own QML engine**
(`src/greeter/GreeterApp.cpp:148`). No QML singleton is shared between them, so the
three screens cannot mirror per-keystroke state — hence one interactive screen and two
that run entirely on their own, rather than three synchronised greeters.

What *is* shared across views is the `sddm` proxy, `userModel`, `sessionModel` and
`keyboard` objects.

SDDM also only activates the view on the DRM-primary screen
(`GreeterApp.cpp:235`), and at greeter time "primary" is whatever the kernel picked —
not necessarily the ultrawide. So the gate view calls `requestActivate()` on itself and
keeps asking until the compositor grants it (`Main.qml`). If the connector named for the
gate is not attached at all, the widest one that is takes the greeter, so the machine is
never left without a login field.

## What the greeter cannot show

Two honest departures from the design, both forced by what a greeter can see:

- **No Wi-Fi SSID.** SDDM has no network API and QML cannot shell out, so that bar slot
  carries `sddm.hostName` instead.
- **The vortex barely appears.** SDDM closes every view the moment a login is accepted
  (`GreeterApp.cpp:173`), so the kawoosh exists mostly for `previewState=success`.

The mission content on the ambience screens — gate addresses, ZPM charge, MALP readings —
is invented. The greeter has no session history and no sensors; it is set dressing, and
it lives in `theme/Config/MissionData.qml` where it can be edited freely.

## Layout

```
nixosModules/sddm-stargate/
├── default.nix                 # options, generated singletons, the theme derivation
└── theme/
    ├── Main.qml                # picks the screen for this view, claims the keyboard
    ├── Config/
    │   ├── qmldir              # declares the three singletons
    │   ├── Theme.qml           # GENERATED — palette, fonts, metrics
    │   ├── Config.qml          # GENERATED — screen roles, geometry, glyphs
    │   └── MissionData.qml     # hand-written mission flavour
    ├── screens/                # GateScreen · DhdScreen · TelemetryScreen
    └── widgets/                # Gate, Dhd, Zpm, bars, lists … plus paint.js
```

`Theme.qml` and `Config.qml` are regenerated on every rebuild from the active
`themes`, `fonts` and `sddm` presets — editing the installed copies under
`/run/current-system` has no effect.

### Two things SDDM will not tell you

`metadata.desktop` must carry **`QtVersion=6`**. `ThemeMetadata.cpp:64` defaults that key
to `5`, and the daemon then looks for a `sddm-greeter` binary that a Qt6-only SDDM does
not ship; it drops the theme and runs its stock one instead
(`Greeter.cpp:95-101`). The only trace is one line in the boot log:

```
The theme at ".../themes/stargate" requires missing ".../bin/sddm-greeter" . Using fallback theme.
```

`Theme-API=2.0` is a different field and does not control this.

**Connector names differ between X11 and Wayland.** The kernel calls the ultrawide
`HDMI-A-2`; the X server calls it `HDMI-2`. The preset quotes DRM names — the same ones
`configurations/hardware/monitors/` uses — and `Main.qml` normalises both sides before
comparing, so one preset works under either greeter.

### Pure QtQuick, on purpose

The theme imports only `QtQuick` and `QtQuick.Window`: no `QtQuick.Controls` (the
password box is a `TextInput`), no `QtQuick.Shapes`, no `Qt5Compat.GraphicalEffects`.
`services.displayManager.sddm.extraPackages` therefore stays empty and a missing QML
plugin can never stop the greeter loading — SDDM's response to a QML error is to fall
back to its own stock theme (`GreeterApp.cpp:205`), which is a bad way to find out.

Everything that is not a rectangle is painted on a `Canvas` through
`widgets/paint.js`: the gate's rim and turning ring, the chevrons and their bloom, the
event horizon, the DHD's thirty-eight keys, the ZPM crystals. Glows are radial-gradient
haloes drawn into the same canvas rather than blur effects.

Each screen is authored in a 1080px-tall space (`Theme.designHeight`) and scaled to the
monitor's real height, so the ultrawide draws the same layout as a 1080p panel, only
wider.

## Preset knobs

`configurations/style/sddm/presets/stargate.nix`:

| Key | What it drives |
|---|---|
| `screens` | connector name per screen role |
| `colors` | Theme palette **names** — chevron, horizon, error, caps |
| `gate` | diameter, chevron radius, ring slots, degrees per character, `maxPreLock`, dial duration |
| `dhd` | diameter, keys per ring, shimmer interval, point of origin |
| `clock24`, `locale` | clock format and the locale dates are rendered in |
| `icons`, `sessionIcons` | Nerd Font codepoints (hex, no backslash) |

## Previewing without a rebuild

`theme.conf` carries two knobs SDDM re-reads at greeter start, so a writable copy of the
theme can be driven through every screen and state on a single display:

```fish
set theme (nix build --no-link --print-out-paths \
  .#nixosConfigurations.mastodant1.config.software.modules.sddm.package)
cp -r $theme/share/sddm/themes/stargate /tmp/stargate; chmod -R u+w /tmp/stargate

# previewScreen = auto | gate | dhd | telemetry
# previewState  = live | dialing | error | capslock | success
sddm-greeter-qt6 --test-mode --theme /tmp/stargate
```

`--test-mode` skips the daemon socket (`GreeterApp.cpp:248`) and still exposes the real
`userModel` and `sessionModel`; `sddm.login()` does nothing, so use `previewState` to see
the failure and vortex states.

To check for QML errors without a display:

```fish
env QT_QPA_PLATFORM=offscreen sddm-greeter-qt6 --test-mode --theme /tmp/stargate
journalctl --user -n 50   # SDDM logs to journald, not stderr
```

"Fallback to embedded theme" in that output means a QML error stopped the theme loading;
the `QQmlError` lines just above it say where.
