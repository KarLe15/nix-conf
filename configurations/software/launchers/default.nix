{ lib, config, ... } : {
  imports = [
  ];
  options.software.launchers = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "rofi"
        "walker"
      ];
      default = "rofi";
      description = ''
        Active launcher preset name. Defines app launcher and clipboard manager commands.
        Consumed by hyprland (shortcuts) and git-accounts (defaultEditor).

        The selected preset must export:
          apply :: { pkgs } -> {
            applications :: LauncherDef;   # app launcher
            clipboard    :: LauncherDef;   # clipboard picker
          }
          autostart :: [ str ]             # e.g. cliphist store watchers

        LauncherDef :: {
          command :: str;
          name    :: str;
          package :: pkg;
        }
      '';
    };
  };
}