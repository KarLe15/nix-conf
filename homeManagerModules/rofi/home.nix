{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.rofi;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.rofi.enable = true;
    home.file.".config/rofi/theme.rasi".text = builtins.readFile ./theme.rasi;
    programs.rofi = {
      enable  = true;
      package = pkgs.rofi;
    };
  };
}
