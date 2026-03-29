{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.zellij;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.zellij.enable = true;
    programs.zellij.enable = true;
  };
}
