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

    bars = {
      browser = {                                            # ultrawide hub — global modules
        left = [
          { w = "clock"; }
          { w = "stub"; icon = "f1f6"; color = "mauve"; }                    # DND (bell-slash)
          { w = "stub"; icon = "f111"; label = "REC"; color = "red"; }      # recording
          { w = "stub"; icon = "f11c"; label = "resize"; color = "peach"; } # submap
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
          { w = "avatar"; }
          { w = "action"; icon = "f015"; color = "blue"; command = fileExplorer "$HOME"; }            # Home
          { w = "action"; icon = "f019"; color = "teal"; command = fileExplorer "$HOME/Downloads"; }  # Downloads
        ];
        center = [ { w = "workspaces"; } ];
        right = [
          { w = "stub"; icon = "f11c"; label = "resize"; color = "peach"; }
          { w = "systemp"; }                                                     # CPU + GPU temps
          { w = "volume"; }
        ];
      };
      terminal = {                                           # right screen — minimal
        left = [
          { w = "clock"; compact = true; }
          { w = "stub"; icon = "f11c"; label = "resize"; color = "peach"; }
        ];
        center = [ { w = "workspaces"; } ];
        right = [
          { w = "stub"; icon = "f108"; label = "LLM my face"; color = "red"; dashed = true; }
          { w = "stub"; icon = "f062"; label = "1.2M"; color = "sky"; }
          { w = "stub"; icon = "f063"; label = "8.4M"; color = "green"; }
        ];
      };
      other = {                                              # any unmapped monitor
        left = [ { w = "clock"; compact = true; } ];
        center = [ { w = "workspaces"; } ];
        right = [ { w = "system"; } { w = "volume"; } ];
      };
    };
  };

  autostart = [
  ];
}
