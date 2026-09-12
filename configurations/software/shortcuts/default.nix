{ lib, config, ... } : {
  imports = [
  ];
  options.software.shortcuts = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "mastodant-1"
      ];
      default = "mastodant-1";
      description = ''
        Active keybinding preset name. Consumed by the hyprland module to build
        Hyprland bind declarations (rendered as hl.bind() calls in hyprland.lua).

        It must also export `submaps`, an attrset of presentation metadata keyed by
        submap name (plus `default`, the no-submap state). The submaps themselves
        are defined by entries carrying `submap = "<name>"`; this is only how the
        Quickshell pill displays them:

          submaps :: { <name> = { name :: str; icon :: str; color :: str; }; }
            name   label shown in the bar
            icon   Nerd Font codepoint (hex, no backslash)
            color  Theme palette name (surface, mauve, peach, ...)

        The selected preset must export a top-level function:
          shortcuts-definition :: { defaults, developpement, launchers, multimedia, pkgs } -> [ ShortcutDef ]

        ShortcutDef :: {
          description :: str;          # shown in Hyprland as the bind description
          mods        :: [ str ];      # modifiers, [ ] for none; joined with "+"
          key         :: str;          # key name, XF86 key, or "mouse:<code>"
          dispatcher  :: str;          # see the dispatcher table below
          args        :: attrs;        # dispatcher arguments, named per dispatcher
          flags       :: attrs;        # hl.bind options: locked / repeating /
                                       #   release / long_press / mouse
          submap      :: str | null;   # submap this bind belongs to, null = global
          env         :: str;          # environment prefix for `exec`
        }

        Every field except `description`, `key` and `dispatcher` has a default, so
        an entry only states what it needs (the preset applies `shortcut-defaults`).

        dispatcher              args
        ----------------------  ------------------------------------------
        exec                    { cmd }
        killactive              —
        forcekillactive         —
        togglefloating          —
        fullscreen              { mode = "fullscreen" | "maximized" }
        togglespecialworkspace  —
        movetoworkspace         { workspace, follow ? true }   # follow = false moves silently
        resize                  { x, y }
        submap-enter            { submap }   # "reset" exits the active submap

        KEY vs KEYCODE: `key` is resolved as an XKB keysym, so it is layout
        dependent. This host is AZERTY (`input.kb_layout = "fr"`), where the
        unshifted number row sends ampersand/eacute/quotedbl/... -- binding "1"
        never matches. Use `key = "code:NN"` for anything positional; `wev`
        prints the keycode to use (number row 1..9 = code:10..code:18).

        Adding a dispatcher means adding a case to `mkDispatcher` in
        homeManagerModules/hyprland/home.nix; an unmapped one throws at eval time.

        NOTE: this preset is imported unwrapped (it exports a function, not
        `apply`), so unlike the other presets its shape is not enforced by a
        submodule type — see custom-config-generator.nix.
      '';
    };
  };
}
