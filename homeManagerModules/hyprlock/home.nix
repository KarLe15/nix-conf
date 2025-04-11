{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
in
{
  stylix.targets.hyprlock = {
    enable = true;
    useWallpaper = false;
  };
  programs.hyprlock = {
    enable = true;
    settings = {
    };
  };
}