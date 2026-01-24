

{inputs, pkgs, lib, config, customConfigs, ... } :
let
in
{
  stylix.targets.zen-browser = {
    enable = true;
    profileNames = [ "Default Profile" ];  # or your actual profile name
  };

  programs.zen-browser = {
    enable = true;
  };
}
