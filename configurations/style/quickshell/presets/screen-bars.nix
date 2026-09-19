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

    bars = {
      browser = {                                            # ultrawide hub — global modules
        left = [
          { w = "session"; }
          { w = "clock"; }
          { w = "stub"; icon = "f1f6"; color = "mauve"; }                    # DND (bell-slash)
          { w = "stub"; icon = "f111"; label = "REC"; color = "red"; }      # recording
          { w = "submap"; }
          { w = "stub"; icon = "f0f4"; color = "teal"; }                    # idle inhibitor
        ];
        center = [ { w = "workspaces"; } ];
        right = [
          { w = "system"; }
          { w = "stub"; icon = "f11b"; color = "green"; }                   # GameMode
          { w = "stub"; icon = "f1de"; label = "scx·rusty"; color = "sky"; }
          { w = "volume"; }
          { w = "stub"; icon = "f0f3"; label = "3"; color = "rosewater"; }  # notifications
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
