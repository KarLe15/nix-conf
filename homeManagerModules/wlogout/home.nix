{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg             = customConfigs.softwareConfigs.modules.wlogout;
  defaultPrograms = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
  powermanagement = customConfigs.softwareConfigs.powermanagement.apply { inherit pkgs; };
in {
  config = lib.mkIf cfg.enable {
    catppuccin.wlogout.enable = false;
    programs.wlogout = {
      enable = true;
      layout = [
        { label = "shutdown"; action = powermanagement.commands.shutdown.command; text = "Shutdown";       keybind = "s"; }
        { label = "reboot";   action = powermanagement.commands.reboot.command;   text = "Reboot";         keybind = "r"; }
        { label = "lock";     action = defaultPrograms.lockscreen.command;        text = "Quick Lock";     keybind = "l"; }
        { label = "suspend";  action = powermanagement.commands.suspend.command;  text = "Lock Power Down"; keybind = "p"; }
        { label = "hibernate";action = powermanagement.commands.hibernate.command;text = "Hibernate";      keybind = "h"; }
      ];
    };
  };
}
