{inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.eww;
in {
  imports = [
  ];

  # programs.eww = {
  #   enable = true;
  #   configDir = ./path/to/your/eww/config;
  #   enableBashIntegration = true; 
  # }

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      eww
    ];
    home.file = {
      ".config/eww" = {
        source = ./config;
        recursive = true;
      };
    };
  };
}