{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.hyprpolkitagent;
in {
  config = lib.mkIf cfg.enable {
    services.hyprpolkitagent = {
      enable  = true;
      package = pkgs.hyprpolkitagent;
    };
  };
}
