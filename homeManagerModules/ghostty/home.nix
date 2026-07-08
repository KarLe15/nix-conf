{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.ghostty;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.ghostty.enable = true;
    programs.ghostty = {
      enable = true;
      settings = {
        font-size   = lib.mkForce 16;
        ## TODO :: ligatures are not working with MesloLG fonts
        font-family = lib.mkForce "JetBrainsMono Nerd Font";
      };
    };
  };
}
