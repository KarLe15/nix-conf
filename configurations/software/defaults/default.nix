{ lib, config, ... } : {
  imports = [
  ];
  options.software.defaults = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "mastodant-1"
      ];
      default = "mastodant-1";
      description = ''
        Active default software preset name. Defines the canonical commands
        for browser, terminal, editor, file manager, email, lock screen, etc.
        Consumed by hyprland, hypridle, wleave, git-accounts, and waybar modules.

        The selected preset must export:
          apply :: { pkgs } -> {
            browser            :: AppDef;
            terminal           :: AppDef;
            terminal-editor    :: AppDef;
            file-explorer      :: AppDef;
            email              :: AppDef;
            notification-center :: AppDef;
            logout             :: AppDef & { env :: str; };
            lockscreen         :: AppDef;
            idlemanager        :: AppDef;
            audiomanager       :: AppDef;
          }
          autostart :: [ str ]

        AppDef :: {
          command :: str;    # shell command to launch the app
          name    :: str;    # human-readable name
          package :: pkg;    # nixpkgs derivation
        }
      '';
    };
  };
}