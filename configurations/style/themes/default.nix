{ lib, config, ... } : {
  imports = [
  ];
  options.style.themes = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "catppuccin-macchiato"
      ];
      default = "catppuccin-macchiato";
      description = ''
        Active color theme preset name.

        The selected preset must export:
          apply :: { pkgs } -> {
            base16-schemes-yaml :: path;   # path to a base16-compatible YAML scheme file
          }
          autostart :: [ str ]
      '';
    };
  };
}