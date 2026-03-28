{ lib, config, ... } : {
  imports = [
  ];
  options.software.powermanagement = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "systemD"
      ];
      default = "systemD";
      description = ''
        Active power management preset name. Defines shutdown/reboot/suspend/hibernate
        commands consumed by hypridle and wleave.

        The selected preset must export:
          apply :: { pkgs } -> {
            commands :: {
              shutdown  :: PowerCommandDef;
              reboot    :: PowerCommandDef;
              suspend   :: PowerCommandDef;
              hibernate :: PowerCommandDef;
            };
            programs :: [ pkg ];   # optional extra packages to install
          }

        PowerCommandDef :: {
          command :: str;
        }
      '';
    };
  };
}