{ lib, config, ... } : {
  imports = [
  ];
  options.style.workspaces = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "standard-3-screen";
      description = "Workspaces defined for navigation";
    };
  };
}