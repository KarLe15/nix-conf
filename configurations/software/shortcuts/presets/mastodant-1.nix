## Keybinding preset. Each entry is a ShortcutDef consumed by
## homeManagerModules/hyprland/home.nix and rendered into an hl.bind() call.
##
##   mods       list of modifiers, [ ] for none — joined with "+" for Hyprland
##   key        key name, XF86 key, or "mouse:<code>"
##   dispatcher what the bind does; mapped to an hl.dsp.* call by mkDispatcher
##   args       dispatcher arguments, named per dispatcher (see the table below)
##   flags      hl.bind options: locked / repeating / release / long_press / mouse
##   submap     submap this bind belongs to, null = always active
##   env        environment prefix for `exec` (kept a raw string; see D6)
##
##   dispatcher              args
##   ----------------------  ------------------------------------------
##   exec                    { cmd }
##   killactive              —
##   forcekillactive         —
##   togglefloating          —
##   fullscreen              { mode = "fullscreen" | "maximized" }
##   togglespecialworkspace  —
##   movetoworkspace         { workspace, follow ? true }
##   resize                  { x, y }
##   submap-enter            { submap }   # "reset" exits the active submap
rec {
  mod = [ "ALT" ];
  mod-shift = [ "ALT" "SHIFT" ];
  secondary = [ "SUPER" ];
  secondary-shift = [ "SUPER" "SHIFT" ];

  ## Defaults every entry inherits, so a ShortcutDef only states what it needs.
  shortcut-defaults = {
    mods = [ ];
    args = { };
    flags = { };
    submap = null;
    env = "";
  };

  shortcuts-definition = {defaults, developpement, launchers, multimedia, pkgs, ...}@programs:
    map (s: shortcut-defaults // s) (
    [
    ## ===========================<     WM Commands    >==========================
    {
      description = "Close Active Window";
      mods = secondary;
      key = "Q";
      dispatcher = "killactive";
    }
    {
      description = "Force Close Active Window";
      mods = secondary-shift;
      key = "Q";
      dispatcher = "forcekillactive";
    }
    {
      description = "FullScreen Active Window (False full screen (with BAR))";
      mods = mod;
      key = "F";
      dispatcher = "fullscreen";
      args = { mode = "maximized"; };
    }
    {
      description = "FullScreen Active Window (True full screen (without BAR))";
      mods = mod-shift;
      key = "F";
      dispatcher = "fullscreen";
      args = { mode = "fullscreen"; };
    }
    {
      description = "Toggle Floating";
      mods = secondary;
      key = "Space";
      dispatcher = "togglefloating";
    }
    {
      description = "Display Special workspace";
      mods = mod;
      key = "twosuperior";
      dispatcher = "togglespecialworkspace";
    }
    {
      description = "Move Special workspace";
      mods = mod-shift;
      key = "twosuperior";
      dispatcher = "movetoworkspace";
      args = { workspace = "special"; follow = false; };
    }
    {
      description = "Open Notification Center";
      mods = mod-shift;
      key = "N";
      dispatcher = "exec";
      args = { cmd = defaults.notification-center.command; };
    }
    ## ===========================<  Session mode  >==============================
    ## See docs/HYPRLAND_SESSIONS.md. ALT+Escape toggles the `session` submap; it
    ## carries submap_universal, so it is also the single escape from *any* submap.
    {
      description = "Session mode";
      mods = mod;
      key = "Escape";
      dispatcher = "session-toggle";
      flags = { submap_universal = true; };
    }
    {
      description = "Next open session";
      submap = "session";
      mods = mod;
      key = "Tab";
      dispatcher = "session-cycle";
      args = { dir = 1; };
    }
    {
      description = "Previous open session";
      submap = "session";
      mods = mod-shift;
      key = "Tab";
      dispatcher = "session-cycle";
      args = { dir = -1; };
    }
  ]
  ## ALT+1..9 inside the submap jump straight to a session, creating it empty.
  ##
  ## Keyed by KEYCODE, not keysym: this host is AZERTY (input.kb_layout = "fr"),
  ## where the number row unshifted sends ampersand/eacute/quotedbl/... — binding
  ## "1" would never match. code:10..code:18 are the physical 1..9 keys on any
  ## layout (the values `wev` reports).
  ++ (map (n: {
    description = "Session ${toString n}";
    submap = "session";
    mods = mod;
    key = "code:${toString (n + 9)}";
    dispatcher = "session-goto";
    args = { session = n; };
  }) (pkgs.lib.range 1 9))
  ++ [
    ## ===========================<  MultiMedia commands  >=======================
    ## TODO :: These are good candidates for flags = { locked = true; repeating = true; }
    ## so they repeat when held and still work on the lock screen.
    {
      description = "Increase the Volume";
      key = "XF86AudioRaiseVolume";
      dispatcher = "exec";
      args = { cmd = multimedia.increaseVolume.command; };
    }
    {
      description = "Lower the Volume";
      key = "XF86AudioLowerVolume";
      dispatcher = "exec";
      args = { cmd = multimedia.lowerVolume.command; };
    }
    {
      description = "Mute / Unmute the Volume";
      key = "XF86AudioPlay";
      dispatcher = "exec";
      args = { cmd = multimedia.toggleVolume.command; };
    }
    ## ===========================<  Locking Commands  >==========================
    {
      description = "Logout Screen";
      mods = secondary;
      key = "L";
      dispatcher = "exec";
      args = { cmd = defaults.logout.command; };
      # FIXME :: 05/05/2025 :: Add this to fix Wlogout / Wleave issue with icons
      env = defaults.logout.env;
    }
    ## ===========================<  Launchers Manage  >==========================
    {
      description = "Application launcher";
      mods = mod;
      key = "Space";
      dispatcher = "exec";
      args = { cmd = launchers.applications.command; };
    }
    {
      description = "Clipboard launcher";
      mods = mod-shift;
      key = "V";
      dispatcher = "exec";
      args = { cmd = launchers.clipboard.command; };
    }
    ## ===========================<  Default programs  >==========================
    {
      description = "Open File Explorer";
      mods = mod-shift;
      key = "Return";
      dispatcher = "exec";
      args = { cmd = defaults.file-explorer.command; };
    }
    {
      description = "Open Terminal";
      mods = mod;
      key = "T";
      dispatcher = "exec";
      args = { cmd = defaults.terminal.command; };
    }
    {
      description = "Open Browser";
      mods = mod;
      key = "B";
      dispatcher = "exec";
      args = { cmd = defaults.browser.command; };
    }
    {
      description = "Take Screenshot and modify";
      key = "mouse:277";
      dispatcher = "exec";
      flags = { submap_universal = true; };
      ## TODO :: 2025-06-10 :: Change this to be modular on a screenshot config standalone
      args.cmd = ''$(grim -g "$(slurp)" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/satty-$(date '+%Y%m%d-%H-%M-%S').png)'';
    }
    {
      description = "Take fullscreen Screenshot and modify";
      mods = [ "SHIFT" ];
      key = "mouse:277";
      dispatcher = "exec";
      flags = { submap_universal = true; };
      ## TODO :: 2025-06-10 :: Change this to be modular on a screenshot config standalone
      args.cmd = ''$(grim -g "$(slurp -o)" -t ppm - | satty --filename - --fullscreen --output-filename ~/Pictures/satty-$(date '+%Y%m%d-%H-%M-%S').png)'';
    }
  ]);
}
