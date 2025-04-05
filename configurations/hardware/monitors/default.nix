{ lib, config, ... } : {
  imports = [
  ];

  options.hardware.monitors = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "mastodant-3-screens";
      description = "Active Monitor setup configuration to use";
    };
  };
}