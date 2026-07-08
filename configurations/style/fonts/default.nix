{ lib, config, ... } : {
  imports = [
  ];
  options.style.fonts = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "mac-like"
      ];
      default = "mac-like";
      description = ''
        Active font family preset name.

        The selected preset must export:
          apply :: { pkgs } -> {
            mono      :: FontDef;
            serif     :: FontDef;
            sansSerif :: FontDef;
            emoji     :: FontDef;
          }

        FontDef :: {
          group-name :: str;   # font family name
          exact-name :: str;   # exact PostScript name passed to Stylix
          package    :: pkg;   # nixpkgs package providing the font
        }
      '';
    };
  };

}