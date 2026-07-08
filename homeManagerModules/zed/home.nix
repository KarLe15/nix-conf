{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.zed;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.zed.enable = true;
    programs.zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "toml"
        "rust"
        "material-icon-theme"
      ];
      userSettings = {
        hour_format      = "hour24";
        auto_update      = false;
        format_on_save   = "off";
        show_whitespaces = "trailing";
        vim_mode         = false;
        load_direnv      = "shell_hook";
        ui_font_size     = lib.mkDefault 20.0;
      };
    };
  };
}
