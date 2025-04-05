{ lib, config, ... } : {
  imports = [
  ];
  options.software.shortcuts = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "mastodant-1";
      description = "Active set of shortcuts";
    };
  };
}