{ lib, config, ... } : {
  imports = [
  ];

  options.style.wallpaper = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "standard";
      description = "Active Wallpaper";
    };
  };
}