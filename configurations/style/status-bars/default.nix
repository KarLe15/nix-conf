{ lib, config, ... } : {
  imports = [
  ];
  options.style.statusbar = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "waybar-3-screen";
      description = "Active Status bar schema";
    };
  };
}