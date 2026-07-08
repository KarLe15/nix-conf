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
        Hyprland bind declarations.

        The selected preset must export a top-level function:
          shortcuts-definition :: { defaults, developpement, launchers, multimedia, pkgs } -> [ ShortcutDef ]

        ShortcutDef :: {
          description     :: str;
          mod1            :: str;            # modifier key, e.g. "ALT", "SUPER", or "" for none
          key             :: str;            # key name or XF86 key
          dispatcher-type :: str;            # Hyprland dispatcher, e.g. "exec", "killactive"
          command         :: str;            # argument to the dispatcher
          env             :: str;            # optional env var prefix for exec dispatchers
        }
      '';
    };
  };
}