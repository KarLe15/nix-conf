{inputs, pkgs, lib, config, customConfigs, ... } :
{
  stylix.targets.rofi = {
    enable = true;
  };
  home.file = {
    ".config/rofi/theme.rasi".text = builtins.readFile ./theme.rasi;
  };
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    ## Change this to be fully managed with Nix
    # theme = lib.mkDefault ./theme.rasi;
  };
}