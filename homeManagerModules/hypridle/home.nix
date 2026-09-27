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
          ## The command is run as-is: keeping itself from starting twice is the
          ## locker's business, not the idle daemon's. The `pidof` guard that used
          ## to live here was written for hyprlock, a long-running process; the
          ## Stargate lock is a one-shot IPC poke that has usually exited before
          ## pidof looks, so the guard could only ever misfire. The preset carries
          ## the guard now, next to the command that needs it.
          lock_cmd        = defaultPrograms.lockscreen.command;
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
