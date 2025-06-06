{
  apply = { pkgs, ... }@inputs: {
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