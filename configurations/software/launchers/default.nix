{ lib, config, ... } : {
  imports = [
  ];
  options.software.launchers = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "walker";
      description = "Active set of Launchers (App Launcher / ClipBoard)";
    };
  };
}