{ lib, config, ... } : {
  imports = [
  ];
  options.style.fonts = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "mac-like";
      description = "Active Fonts theme defined for different parts for system";
    };
  };

}