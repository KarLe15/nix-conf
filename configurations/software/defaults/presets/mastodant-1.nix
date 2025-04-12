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
    logout = {
      command = "wleave -kf > /tmp/karim.txt";
      name = "WLeave";
      package = pkgs.wleave;
    };
    lockscreen = {
      command = "hyprlock";
      name = "Hyprlock";
      package = pkgs.hyprlock;
    };
  };

  autostart = [
  ];
}