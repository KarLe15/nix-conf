{
  apply = { pkgs, ... }: {
    wallpaper = [
      pkgs.hyprpaper

    ];
    clipboard = [
      pkgs.cliphist
      pkgs.wl-clipboard
    ];
    screenshot = [
      pkgs.grim   # screenshot utils
      pkgs.slurp  # region selector
      pkgs.satty  # annotation tool
    ];
    extra = [
      pkgs.hyprsysteminfo
      ## Pipewire utils
      pkgs.easyeffects # # Manage Inputs / Output for audio
      pkgs.overskride # # Bluetooth App
      pkgs.hyprpwcenter
    ];
  };

  autostart = [];
}
