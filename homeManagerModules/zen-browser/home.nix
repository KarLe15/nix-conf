{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.zen-browser;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.zen-browser = {
      enable       = true;
      profileNames = [ "Default Profile" ];
    };
    programs.zen-browser.enable = true;
  };
}
