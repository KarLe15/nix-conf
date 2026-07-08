{ lib }:
let
  lib-types    = import ../../lib/types.nix { inherit lib; };
  packageType  = lib-types.packageType;

  powerCommandType = lib.types.submodule {
    options = {
      command = lib.mkOption {
        type        = lib.types.str;
        description = "Shell command for this power action.";
      };
    };
  };
in
{
  powermanagementOutputType = lib.types.submodule {
    options = {
      idleTimeouts = lib.mkOption {
        type = lib.types.submodule {
          options = {
            lockAfter      = lib.mkOption { type = lib.types.int; description = "Seconds of inactivity before locking the session."; };
            screenOffAfter = lib.mkOption { type = lib.types.int; description = "Seconds of inactivity before turning off the screen."; };
            suspendAfter   = lib.mkOption { type = lib.types.int; description = "Seconds of inactivity before suspending the system."; };
          };
        };
      };
      commands = lib.mkOption {
        type = lib.types.submodule {
          options = {
            shutdown  = lib.mkOption { type = powerCommandType; };
            reboot    = lib.mkOption { type = powerCommandType; };
            suspend   = lib.mkOption { type = powerCommandType; };
            hibernate = lib.mkOption { type = powerCommandType; };
          };
        };
      };
      programs = lib.mkOption {
        type    = lib.types.listOf packageType;
        default = [];
      };
    };
  };
}
