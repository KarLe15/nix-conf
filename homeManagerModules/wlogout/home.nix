{inputs, pkgs, lib, config, catpuccin, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
  defaultPrograms = softwareConfigs.defaults.apply { inherit pkgs; };
  powermanagement = softwareConfigs.powermanagement.apply { inherit pkgs; };
in
{
  catppuccin.wlogout.enable = true;
  programs.wlogout = {
    enable = true;
    ## TODO :: 18/04/2025 :: Add an if to check if config for wleave or wlogout 
    ##         WLeave neads the "buttons" at top level to have a proper json format
    layout = [
      {
        buttons = [
          {
            label = "shutdown";
            action = powermanagement.commands.shutdown.command;
            text = "Shutdown";
            keybind = "s";
          }
          {
            label = "reboot";
            action = powermanagement.commands.reboot.command;
            text = "Reboot";
            keybind = "r";
          }
          {
            label = "lock";
            ## TODO :: 11/04/2025 :: Using directly the command instead of loginctl
            action = defaultPrograms.lockscreen.command;
            text = "Quick Lock";
            keybind = "l";
          }
          {
            label = "suspend";
            action = powermanagement.commands.suspend.command;
            text = "Lock Power Down";
            keybind = "p";
          }
          {
            label = "hibernate";
            action = powermanagement.commands.hibernate.command;
            text = "Hibernate";
            keybind = "h";
          }
        ];
      }
    ];
  };
}