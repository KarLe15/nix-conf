{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.swaync;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.swaync.enable = true;
    services.swaync = {
      enable   = true;
      package  = pkgs.swaynotificationcenter;
      style    = "";
      settings = {};
    };
  };
}
