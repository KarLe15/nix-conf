{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg             = customConfigs.softwareConfigs.modules.hypridle;
  defaultPrograms = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
  powermanagement = customConfigs.softwareConfigs.powermanagement.apply { inherit pkgs; };
  timeouts        = powermanagement.idleTimeouts;
in {
  config = lib.mkIf cfg.enable {
    services.hypridle = {
      enable  = true;
      package = pkgs.hypridle;
      settings = {
        general = {
          lock_cmd        = let locker = defaultPrograms.lockscreen.command;
                            in "pidof ${locker} || ${locker}";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout    = timeouts.lockAfter;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout    = timeouts.screenOffAfter;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }
          {
            timeout    = timeouts.suspendAfter;
            on-timeout = powermanagement.commands.suspend.command;
          }
        ];
      };
    };
  };
}
