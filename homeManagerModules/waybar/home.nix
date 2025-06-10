{inputs, pkgs, lib, config, catpuccin, customConfigs, ... } : let 
  enabled = customConfigs.softwareConfigs.modules.waybar.enable;
in 
{
  stylix.targets.waybar.enable = false;
  programs = lib.mkIf enabled {
    waybar = let 
      monitors = customConfigs.hardwareConfigs.monitors.apply { inherit pkgs; };
      workspaces = customConfigs.styleConfigs.workspaces.apply { inherit pkgs monitors; };
      default-programs = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
      multimedia-programs = customConfigs.softwareConfigs.multimedia.apply { inherit pkgs; };
      status-bar = customConfigs.styleConfigs.status-bars.apply {inherit workspaces default-programs multimedia-programs pkgs;};
    in {
      enable = true;
      systemd.enable = true;
      style = status-bar.style-file;
      settings = let 
        waybarUtils = import ./utils.nix {inherit pkgs lib ;};
      in lib.map (bar: waybarUtils.buildBarObject bar) status-bar.bars;
    };
  };
}