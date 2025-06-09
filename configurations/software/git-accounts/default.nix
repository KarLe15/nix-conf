{ lib, config, ... } : {
  imports = [
  ];
  options.software.git-accounts = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "standard";
      description = "List of all SSH accounts configured for GIT and default editor";
    };
  };
}