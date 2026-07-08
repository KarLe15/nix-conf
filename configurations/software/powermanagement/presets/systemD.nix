{
  apply = { pkgs, ... }@inputs: {
    idleTimeouts = {
      lockAfter      = 600;
      screenOffAfter = 700;
      suspendAfter   = 900;
    };
    commands = {
      shutdown = {
        command = "systemctl poweroff";
      };
      reboot = {
        command = "systemctl reboot";
      };
      suspend = {
        command = "systemctl suspend";
      };
      hibernate = {
        command = "systemctl hibernate";
      };
    };
    programs = [];
  };
}