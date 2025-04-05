{ lib, config, ... } : {
  imports = [
  ];

  options.style.cursors = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "Bibata";
      description = "Active Cursor theme name for system";
    };
  };
}