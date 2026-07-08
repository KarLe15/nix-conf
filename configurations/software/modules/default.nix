{ lib, ... }: {
  options.software.modules = {
    waybar = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Waybar status bar Home Manager module.";
      };
    };
    git-accounts = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable multi-account SSH and git configuration generation.";
      };
    };
    ghostty = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Ghostty terminal Home Manager module.";
      };
    };
    catppuccin = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Catppuccin theme fallback Home Manager module.";
      };
    };
    hypridle = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Hypridle idle management Home Manager module.";
      };
    };
    wleave = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Wleave power menu Home Manager module.";
      };
    };
    zed = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Zed editor Home Manager module.";
      };
    };
    rofi = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Rofi app launcher Home Manager module.";
      };
    };
    swaync = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Swaync notification center Home Manager module.";
      };
    };
    avizo = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Avizo volume OSD Home Manager module.";
      };
    };
    brave = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Brave browser Home Manager module.";
      };
    };
    zen-browser = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Zen browser Home Manager module.";
      };
    };
    hyprlock = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Hyprlock screen locker Home Manager module.";
      };
    };
    hyprpolkitagent = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Hyprpolkitagent PolicyKit agent Home Manager module.";
      };
    };
    zellij = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Zellij terminal multiplexer Home Manager module.";
      };
    };
    wlogout = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Wlogout power menu Home Manager module (disabled in favour of wleave).";
      };
    };
    jetbrains = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the JetBrains IDEs Home Manager module.";
      };
    };
    starship = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Starship prompt Home Manager module.";
      };
    };
    fish = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Fish shell Home Manager module.";
      };
    };
    hyprland = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Hyprland compositor Home Manager module.";
      };
    };
    wayland-desktop = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Wayland desktop utilities module (wallpaper, clipboard, screenshots).";
      };
    };
    quickshell = {
      enable = lib.mkOption {
        type    = lib.types.bool;
        default = false;
        description = "Enable the Quickshell (QtQuick/QML) desktop shell Home Manager module.";
      };
    };
  };
}
