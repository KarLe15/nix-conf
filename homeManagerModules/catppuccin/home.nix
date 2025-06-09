{inputs, pkgs, lib, config, catpuccin, customConfigs, ... } : 
let 
  cursor = customConfigs.styleConfigs.cursors.apply { inherit pkgs; };
in
{
  catppuccin.flavor = "macchiato";
}