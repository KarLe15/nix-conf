{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg            = customConfigs.softwareConfigs.modules.wayland-desktop;
  wayland-desktop = customConfigs.softwareConfigs.wayland-desktop.apply { inherit pkgs; };
in {
  config = lib.mkIf cfg.enable {
    home.packages =
      wayland-desktop.wallpaper ++
      wayland-desktop.clipboard ++
      wayland-desktop.screenshot ++
      wayland-desktop.extra;
  };
}
