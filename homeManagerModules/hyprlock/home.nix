{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.hyprlock;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.hyprlock = {
      enable       = true;
      useWallpaper = false;
    };
    programs.hyprlock = {
      enable   = true;
      settings = {};
    };
  };
}
