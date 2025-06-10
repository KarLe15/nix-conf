{
  apply = { pkgs, ... }@inputs: {
    applications = {
      ## TODO :: 2025-06-10 :: change this to more reliable config
      command = "rofi -show drun -theme /home/karim/.config/rofi/theme.rasi";
      name = "Rofi launcher with theme";
      package = pkgs.rofi-wayland;
    };
    clipboard = {
      ## TODO :: 2025-06-10 :: change this to more reliable config
      command = " cliphist list | rofi -dmenu -theme /home/karim/.config/rofi/theme.rasi | cliphist decode | wl-copy";
      name = "Rofi launcher with theme";
      package = pkgs.rofi-wayland;
    };
  };
  autostart = [
    ## TODO :: 2025-06-10 :: change this to a clipboard manager config standalone
    "wl-paste --type text --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
  ];
}

