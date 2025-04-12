{inputs, pkgs, lib, config, catpuccin, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
in
{
  catppuccin.flavor = "macchiato";
}