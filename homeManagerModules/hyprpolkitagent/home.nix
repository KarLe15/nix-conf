{inputs, pkgs, lib, config, customConfigs, ... } : 
{
  services.hyprpolkitagent = {
    enable = true;
    package = pkgs.hyprpolkitagent;
  };
}