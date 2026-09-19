# Quickshell "Screen Bars · Filled" preset. Owns the shell's per-screen composition
# and assets, consumed by homeManagerModules/quickshell/home.nix via customConfigs.
#
# `bars` is keyed by monitor role (code/terminal/browser/other). Each zone
# (left/center/right) is a list of entries, each either a real widget
# ({ w = "clock"; }) or a design stub ({ w = "stub"; icon; label; color; }):
#   icon    Nerd Font codepoint (hex, no backslash) — serialized as \uXXXX
#   color   Theme palette name (e.g. "peach", "sapphire")
#   command shell command run on click ({ w = "action"; }) — launched detached
#   compact clock time-only (no date)
#   dashed  stub drawn with a dashed ring ("conditional"/troll pills)
# Real widget names are dispatched by qml/widgets/WidgetSlot.qml; unknown names
# fall back to a StubPill built from the entry data.
{
  apply = { default-programs, ... }:
  let
    # Launch actions are built from the default programs (single source of truth).
    fileExplorer = dir: ''${default-programs.file-explorer.command} "${dir}"'';
  in {
    profile-image = ../../status-bars/assets/profile_oneill.jpg;

    ## Multimedia OSD (Volume OSD · design ids 9a/9c/9d). A transient overlay
    ## fired by volume/mic changes. `variant = "all"` renders every alternative at
    ## once for review — they occupy different thirds of the screen so they do not
    ## collide.
    ##   monitor    monitor ROLE the OSD renders on (code/terminal/browser/other)
    ##   variant    "card" (9a) | "ring" (9c) | "notch" (9d) | "all"
    ##   accent     Theme palette name
    ##   holdMs     time the OSD stays up; each change restarts it (design: 1600)
    ##   fadeMs     appearance fade (design: 180)
    ##   placement  card only: "bottom" | "top"
    ##   margin     distance from the screen edge
    ##   cardWidth  9a card min width
    ##   lowThreshold  % below which the "volume down" glyph is shown
    ##   showDevice whether the device line is rendered
    ##   icons      Nerd Font codepoints (hex, no backslash). The design specifies
    ##              Tabler webfont glyphs; these are the Font Awesome equivalents
    ##              carried by the Nerd Font the fonts preset selects.
    osd = {
      monitor      = "terminal";   # bottom-right screen
      variant      = "card";        # set to "card" once a variant is chosen
      accent       = "blue";       # #8aadf4
      holdMs       = 1600;         # hold window; each change restarts it
      fadeMs       = 180;          # appearance fade
      placement    = "bottom";
      margin       = 46;           # distance from the screen edge
      cardWidth    = 340;          # 9a card min width
      lowThreshold = 45;           # % below which the "volume down" glyph is used
      showDevice   = true;         # the device line under the level bar
      icons = {
        volumeHigh = "f028";    # nf-fa-volume_up        (ti-volume)
        volumeLow  = "f027";    # nf-fa-volume_down      (ti-volume-2)
        volumeMute = "f026";    # nf-fa-volume_off       (ti-volume-3)
        micOn      = "f130";    # nf-fa-microphone       (ti-microphone)
        micMute    = "f131";    # nf-fa-microphone_slash (ti-microphone-off)
      };
    };

    ## Command palette (design "App Launcher" · id 2a). One centred surface with a
    ## search field, a mode badge and a rich-row list. The design's framing is
    ## "one component, every mode" — Apps is the only mode implemented so far;
    ## clipboard/emoji/pass slot in beside it without touching the shell.
    ##   monitor         monitor ROLE to render on, or "focused" to follow focus
    ##   accent          Theme palette name — badge, caret, selection, keybind chip
    ##   selectionStyle  "tint" | "fill" | "outline" | "bar" (design Tweaks)
    ##   quickKeys       show 2..9 quick-jump numbers on rows (design Tweaks)
    ##   width           palette width (design: 624)
    ##   position        "center" (vertically centred) | "top" (topMargin below the edge)
    ##   topMargin       distance from the top when position = "top" (design: 64)
    ##   scrim           desktop dim behind the palette, 0..1. The design says 0.62,
    ##                   which reads gently on its 1160x576 mock and heavily across
    ##                   a real screen — lowered to 0.35.
    ##   maxRows         rows shown before the list scrolls
    ##   fixedHeight     keep the list at maxRows regardless of how many results
    ##                   match. false lets the box shrink as you filter — which,
    ##                   combined with position = "center", also makes it drift.
    palette = {
      monitor        = "focused";
      accent         = "mauve";
      selectionStyle = "fill";
      quickKeys      = false;
      width          = 624;
      position       = "center";
      topMargin      = 64;
      scrim          = 0.35;
      maxRows        = 8;
      fixedHeight    = true;
    };


    ## Avatar control centre (design "Avatar Widget" · ids 9a + 9b, network variant
    ## 10b). The bar avatar is the photo disc whose ring carries presence; clicking
    ## it drops a popover with identity, the presence switch, the idle inhibitor and
    ## the network block. Session actions (lock/reboot/power) live elsewhere by
    ## design. The ring is the only bar indicator — no glyph, no count.
    ##   width          popover width (design: 372) = 340 inner + 2x16 padding
    ##   discSize       identity-row disc; the bar disc stays Theme.pillHeight
    ##   ringWidth      bar ring thickness, then ringGap of background inside it
    ##   panelRingWidth ring thickness on the larger identity-row disc
    ##   userName       display name in the popover; "" derives it from $USER
    ##   presence       Theme palette name per presence state. Focus and DND both
    ##                  mean "swaync DND on" until the notification centre lands —
    ##                  see qml/Presence.qml.
    ##   idleDurations  keep-awake chips, in minutes; 0 renders as "∞"
    ##   idleDefault    duration used when the switch is flipped without a chip
    ##   netListHeight  SSID list height before it scrolls
    ##   facts          rows of the facts block, in order (uptime/kernel/session/shell)
    ##   mirrors        read-only pills on the hub bar echoing this state; they have
    ##                  no actions — the popover is the only place that changes it
    ##   icons          Nerd Font codepoints (hex, no backslash). The design specifies
    ##                  Tabler webfont glyphs; these are the Font Awesome equivalents
    ##                  carried by the Nerd Font the fonts preset selects.
    avatar = {
      width          = 372;
      discSize       = 52;
      ringWidth      = 2;
      ringGap        = 2;
      panelRingWidth = 3;
      userName       = "";
      presence = {
        available = "green";      # #a6da95
        focus     = "yellow";     # #eed49f
        dnd       = "red";        # #ed8796
      };
      idleDurations = [ 30 60 240 0 ];
      idleDefault   = 60;
      netListHeight = 208;
      facts         = [ "uptime" "kernel" "session" "shell" ];
      mirrors = {
        presence      = true;
        idle          = true;
        notifications = true;
      };
      icons = {
        available    = "f058";  # nf-fa-check_circle       (ti-circle-check)
        focus        = "f140";  # nf-fa-bullseye           (ti-target)
        dnd          = "f1f6";  # nf-fa-bell_slash         (ti-bell-off)
        bell         = "f0f3";  # nf-fa-bell               (ti-bell)
        awake        = "f0f4";  # nf-fa-coffee             (ti-coffee)
        asleep       = "f186";  # nf-fa-moon_o             (ti-moon-z-z)
        wired        = "f1e6";  # nf-fa-plug               (ti-plug-connected)
        wifi         = "f1eb";  # nf-fa-wifi               (ti-wifi)
        check        = "f00c";  # nf-fa-check              (ti-check)
        lock         = "f023";  # nf-fa-lock               (ti-lock)
        chevronUp    = "f077";  # nf-fa-chevron_up         (ti-chevron-up)
        chevronDown  = "f078";  # nf-fa-chevron_down       (ti-chevron-down)
        user         = "f007";  # nf-fa-user — photo fallback
      };
    };

    bars = {
      browser = {                                            # ultrawide hub — global modules
        left = [
          { w = "session"; }
          { w = "clock"; }
          { w = "presence"; }                                              # mirrors the avatar ring
          { w = "stub"; icon = "f111"; label = "REC"; color = "red"; }      # recording
          { w = "submap"; }
          { w = "idle"; }                                                  # mirrors "Keep awake"
        ];
        center = [ { w = "workspaces"; } ];
        right = [
          { w = "system"; }
          { w = "stub"; icon = "f11b"; color = "green"; }                   # GameMode
          { w = "stub"; icon = "f1de"; label = "scx·rusty"; color = "sky"; }
          { w = "volume"; }
          { w = "notifications"; }                                         # swaync count; hidden at zero
        ];
      };
      code = {                                               # left screen — primary
        left = [
          { w = "session"; }
          { w = "avatar"; }
          { w = "action"; icon = "f015"; color = "blue"; command = fileExplorer "$HOME"; }            # Home
          { w = "action"; icon = "f019"; color = "teal"; command = fileExplorer "$HOME/Downloads"; }  # Downloads
        ];
        center = [ { w = "workspaces"; } ];
        right = [
          { w = "submap"; }
          { w = "systemp"; }                                                     # CPU + GPU temps
          { w = "volume"; }
        ];
      };
      terminal = {                                           # right screen — minimal
        left = [
          { w = "session"; }
          { w = "clock"; compact = true; }
          { w = "submap"; }
        ];
        center = [ { w = "workspaces"; } ];
        right = [
          { w = "stub"; icon = "f108"; label = "LLM my face"; color = "red"; dashed = true; }
          { w = "network"; }                                                   # upload + download rates
        ];
      };
      other = {                                              # any unmapped monitor
        left = [ { w = "session"; } { w = "clock"; compact = true; } ];
        center = [ { w = "workspaces"; } ];
        right = [ { w = "system"; } { w = "volume"; } ];
      };
    };
  };

  autostart = [
  ];
}
