

{inputs, pkgs, lib, config, customConfigs, ... } : 
let 
in
{
  stylix.targets.zellij.enable = true;
  programs.zellij = {
    enable = true;
  };
}
