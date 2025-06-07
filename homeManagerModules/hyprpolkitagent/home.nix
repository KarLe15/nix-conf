{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
in
{
  stylix.targets.hyprlock = {
    enable = true;
    useWallpaper = false;
  };
  services.hyprpolkitagent = {
    enable = true;
    package = pkgs.hyprpolkitagent;
  };
}