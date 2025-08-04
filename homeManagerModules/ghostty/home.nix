

{inputs, pkgs, lib, config, customConfigs, ... } : 
let 
in
{
  stylix.targets.ghostty.enable = true;
  programs.ghostty = {
    enable = true;
    settings = {
      font-size = lib.mkForce 16;
      ## TODO :: the ligature are not working with MesloLG fonts
      font-family = lib.mkForce "JetBrainsMono Nerd Font";
    };
  };
}
