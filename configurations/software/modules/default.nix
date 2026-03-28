{ lib, ... }: {
  options.software.modules = {
    waybar = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the Waybar status bar Home Manager module.";
      };
    };
    eww = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Eww widget system Home Manager module.";
      };
    };
    walker = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Walker app launcher Home Manager module.";
      };
    };
    git-accounts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable multi-account SSH and git configuration generation.";
      };
    };
  };
}
