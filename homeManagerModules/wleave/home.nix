{inputs, pkgs, lib, config, catpuccin, customConfigs, ... } :
let
  defaultPrograms = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
  powermanagement = customConfigs.softwareConfigs.powermanagement.apply { inherit pkgs; };
in
{
  catppuccin.wleave.enable = false;
  programs.wleave = {
    enable = true;
    ## TODO :: 18/04/2025 :: Add an if to check if config for wleave or wlogout
    ##         WLeave neads the "buttons" at top level to have a proper json format
    settings = {
      margin = 200;
        buttons-per-row = "2/3";
        delay-command-ms = 100;
        close-on-lost-focus = true;
        show-keybinds = true;
        buttons = [
          {
            label = "shutdown";
            action = powermanagement.commands.shutdown.command;
            text = "Shutdown";
            keybind = "s";
            icon = "${pkgs.wleave}/share/wleave/icons/shutdown.svg";
          }
          {
            label = "reboot";
            action = powermanagement.commands.reboot.command;
            text = "Reboot";
            keybind = "r";
            icon = "${pkgs.wleave}/share/wleave/icons/reboot.svg";
          }
          {
            label = "lock";
            action = defaultPrograms.lockscreen.command;
            text = "Quick Lock";
            keybind = "l";
            icon = "${pkgs.wleave}/share/wleave/icons/lock.svg";
          }
          {
            label = "suspend";
            action = powermanagement.commands.suspend.command;
            text = "Lock Power Down";
            keybind = "p";
            icon = "${pkgs.wleave}/share/wleave/icons/suspend.svg";
          }
          {
            label = "hibernate";
            action = powermanagement.commands.hibernate.command;
            text = "Hibernate";
            keybind = "h";
            icon = "${pkgs.wleave}/share/wleave/icons/hibernate.svg";
          }
        ];
    };
  };
}
