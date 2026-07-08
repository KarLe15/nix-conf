{ lib, config, ... } : {
  imports = [
  ];

  options.style.cursors = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "Bibata"
      ];
      default = "Bibata";
      description = ''
        Active cursor theme preset name.

        The selected preset must export:
          apply :: { pkgs } -> {
            default :: {
              group-name :: str;    # cursor theme family name
              exact-name :: str;    # exact theme name passed to hyprctl setcursor
              size       :: int;    # cursor size in pixels
              package    :: pkg;
            };
          }
          autostart :: [ str ]
      '';
    };
  };
}