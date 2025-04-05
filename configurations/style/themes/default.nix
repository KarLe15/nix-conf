{ lib, config, ... } : {
  imports = [
  ];
  options.style.themes = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin-macchiato";
      description = "Active theme name for system";
    };
  };
}