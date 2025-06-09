{inputs, pkgs, lib, config, customConfigs, ... } :
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