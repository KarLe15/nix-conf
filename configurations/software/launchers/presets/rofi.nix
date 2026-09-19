{
  apply = { pkgs, ... }@inputs: {
    ## NOTE 2026-09-20: no longer bound. ALT+Space opens the Quickshell command
    ## palette instead (see the shortcuts preset). Kept so the preset still
    ## satisfies its contract and the rofi launcher remains one edit away.
    applications = {
      command = "rofi -show drun -theme /home/karim/.config/rofi/theme.rasi";
      name = "Rofi launcher with theme";
      package = pkgs.rofi;
    };
    clipboard = {
      ## TODO :: 2025-06-10 :: change this to more reliable config
      command = " cliphist list | rofi -dmenu -theme /home/karim/.config/rofi/theme.rasi | cliphist decode | wl-copy";
      name = "Rofi launcher with theme";
      package = pkgs.rofi;
    };
  };
  autostart = [
    ## TODO :: 2025-06-10 :: change this to a clipboard manager config standalone
    "wl-paste --type text --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
  ];
}
