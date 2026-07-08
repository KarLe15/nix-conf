{ lib, config, ... } : {
  imports = [
  ];

  options.style.wallpaper = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "standard"
      ];
      default = "standard";
      description = ''
        Active wallpaper preset name. The preset is consumed by the nixCommonModules
        Stylix configuration to set the system wallpaper.

        The selected preset must export:
          apply :: { pkgs } -> {
            default :: {
              path :: path;   # absolute path to an image file
            };
          }
      '';
    };
  };
}