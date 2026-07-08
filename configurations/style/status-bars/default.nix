{ lib, config, ... } : {
  imports = [
  ];
  options.style.statusbar = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "waybar-3-screen"
      ];
      default = "waybar-3-screen";
      description = ''
        Active status bar layout preset name.

        The selected preset must export:
          apply :: { pkgs, workspaces, default-programs, multimedia-programs } -> {
            style-file :: path;    # path to a Waybar CSS file
            bars       :: [ BarDef ];
          }
          autostart :: [ str ]

        BarDef is the declarative bar config consumed by
        homeManagerModules/waybar/utils.nix:buildBarObject.
        See homeManagerModules/waybar/README.md for the full BarDef schema.
      '';
    };
  };
}