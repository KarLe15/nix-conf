{inputs, pkgs, lib, config, catpuccin, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
in
{
  catppuccin.wlogout.enable = true;
  programs.wlogout = {
    enable = true;
    ## TODO :: 11/04/2025 :: Use SystemD commands for now
    layout = [
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "lock";
        ## TODO :: 11/04/2025 :: Using directly the command instead of loginctl
        action = "hyprlock";
        text = "Quick Lock";
        keybind = "l";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Lock Power Down";
        keybind = "p";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
    ];
  };
}