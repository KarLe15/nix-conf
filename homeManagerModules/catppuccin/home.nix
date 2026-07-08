{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg    = customConfigs.softwareConfigs.modules.catppuccin;
  themes = customConfigs.styleConfigs.themes.apply { inherit pkgs; };
in {
  config = lib.mkIf cfg.enable {
    catppuccin.flavor = themes.flavor;
  };
}
