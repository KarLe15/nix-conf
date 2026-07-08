{ lib, config, ... } : {
  imports = [
  ];
  options.software.multimedia = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "avizo"
      ];
      default = "avizo";
      description = ''
        Active multimedia control preset name. Defines volume/brightness commands
        for keybindings and the Waybar wireplumber module.

        The selected preset must export:
          apply :: { pkgs } -> {
            increaseVolume :: MediaCommandDef;
            lowerVolume    :: MediaCommandDef;
            toggleVolume   :: MediaCommandDef;
          }

        MediaCommandDef :: {
          description :: str;
          command     :: str;
        }
      '';
    };
  };
}