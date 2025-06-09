{inputs, pkgs, lib, config, customConfigs, ... } :
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