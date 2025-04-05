{ lib, config, ... } : {
  imports = [
  ];
  options.software.defaults = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "mastodant-1";
      description = "Active set of default software (brower / terminal / File-Explorer / Emails)";
    };
  };
}