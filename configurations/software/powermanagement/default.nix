{ lib, config, ... } : {
  imports = [
  ];
  options.software.powermanagement = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "systemD";
      description = "Active set of powermanagement tools";
    };
  };
}