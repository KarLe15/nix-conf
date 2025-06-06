{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
in
{
  stylix.targets.swaync = {
    enable = true;
  };
  services.swaync = {
    enable = true;
    package = pkgs.swaynotificationcenter;
    style = ''

    '';
    settings = {
    };
  };
}