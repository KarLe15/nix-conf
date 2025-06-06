{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
  defaultPrograms = softwareConfigs.defaults.apply { inherit pkgs; };
  powermanagement = softwareConfigs.powermanagement.apply { inherit pkgs; };
in
{
  services.hypridle = {
    enable = true;
    package = pkgs.hypridle;
    settings = {
      general = {
        lock_cmd = let 
            locker = defaultPrograms.lockscreen.command;  
          in 
          "pidof ${locker} || ${locker}";
        after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 700;
          on-timeout = "hyprctl dispatch dpms off"; # screen off when timeout has passed
          on-resume = "hyprctl dispatch dpms on"; # screen on when activity is detected after timeout has fired.
        }
        {
          timeout = 900;
          on-timeout = powermanagement.commands.suspend.command;
        }
      ];
    };
  };
}