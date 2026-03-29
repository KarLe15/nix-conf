{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg             = customConfigs.softwareConfigs.modules.wleave;
  defaultPrograms = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
  powermanagement = customConfigs.softwareConfigs.powermanagement.apply { inherit pkgs; };
in {
  config = lib.mkIf cfg.enable {
    catppuccin.wleave.enable = false;
    programs.wleave = {
      enable = true;
      settings = {
        margin               = 200;
        buttons-per-row      = "2/3";
        delay-command-ms     = 100;
        close-on-lost-focus  = true;
        show-keybinds        = true;
        buttons = [
          {
            label   = "shutdown";
            action  = powermanagement.commands.shutdown.command;
            text    = "Shutdown";
            keybind = "s";
            icon    = "${pkgs.wleave}/share/wleave/icons/shutdown.svg";
          }
          {
            label   = "reboot";
            action  = powermanagement.commands.reboot.command;
            text    = "Reboot";
            keybind = "r";
            icon    = "${pkgs.wleave}/share/wleave/icons/reboot.svg";
          }
          {
            label   = "lock";
            action  = defaultPrograms.lockscreen.command;
            text    = "Quick Lock";
            keybind = "l";
            icon    = "${pkgs.wleave}/share/wleave/icons/lock.svg";
          }
          {
            label   = "suspend";
            action  = powermanagement.commands.suspend.command;
            text    = "Lock Power Down";
            keybind = "p";
            icon    = "${pkgs.wleave}/share/wleave/icons/suspend.svg";
          }
          {
            label   = "hibernate";
            action  = powermanagement.commands.hibernate.command;
            text    = "Hibernate";
            keybind = "h";
            icon    = "${pkgs.wleave}/share/wleave/icons/hibernate.svg";
          }
        ];
      };
    };
  };
}
