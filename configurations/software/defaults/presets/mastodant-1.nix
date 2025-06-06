{
  apply = { pkgs, ... }@inputs: {
    browser = {
      command = "firefox";
      name = "Firefox";
      package = pkgs.firefox-unwrapped;
    };
    terminal = {
      command = "ghostty";
      name = "Ghostty";
      package = pkgs.ghostty;
    };
    file-explorer = {
      command = "nautilus";
      name = "Nautilus";
      package = pkgs.nautilus;
    };
    email = {
      command = "thunderbird";
      name = "ThunderBird";
      package = pkgs.thunderbird-latest-unwrapped;
    };
    notification-center = {
      command = "swaync-client -t";
      name = "Open notification Center";
      package = pkgs.swaynotificationcenter;
    };
    logout = {
      command = "wleave -kf";
      name = "WLeave";
      package = pkgs.wleave;
      # FIXME :: 05/05/2025 :: Add this to fix Wlogout / Wleave issue with icons
      env = "GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };
    lockscreen = {
      command = "hyprlock";
      name = "Hyprlock";
      package = pkgs.hyprlock;
    };
    idlemanager = {
      command = "hypridle";
      name = "HyprIdle";
      package = pkgs.hypridle;
    };
  };

  autostart = [
  ];
}