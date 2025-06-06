{ lib, config, ... } : {
  imports = [
  ];
  options.software.multimedia = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "avizo";
      description = "Active set of Multimedia Scripts / programs";
    };
  };
}