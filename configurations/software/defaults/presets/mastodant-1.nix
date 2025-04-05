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
  };

  autostart = [
  ];
}