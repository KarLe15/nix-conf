{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.software.modules.thrustmaster-wheel;
in
{
  options.software.modules.thrustmaster-wheel = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the out-of-tree hid-tmff2 driver for Thrustmaster force-feedback
        wheels (T300RS, T248, T128, TX, TS-XW, TS-PC).
      '';
    };

    oversteer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install Oversteer and its udev rules. The rules chmod the driver's
        sysfs attributes (range, gain, spring_level, ...) so Oversteer can
        write them without root.
      '';
    };

    deadzoneFix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install hid-tmff2's udev rule clearing the evdev deadzone on the wheel
        axis, ported off the hardcoded /usr/bin paths it ships with.
      '';
    };

    productIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "b66e" "b66f" "b66d" "b696" "b669" "b692" "b689" ];
      description = ''
        USB product IDs (vendor 044f) the deadzone rule applies to. Defaults to
        the wheels hid-tmff2 claims; the T248 is b696.
      '';
    };

    timerMsecs = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 4;
      description = ''
        Force-feedback timer period for hid-tmff-new. The driver default is 8;
        some games behave better as low as 2. null leaves it untouched.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    ## The package is named hid-tmff2, but the modules it installs are
    ## hid-tmff-new (force feedback, 044f:b696 for the T248) and
    ## hid-tminit-new / usb-tminit-new (mode init, 044f:b69c).
    boot.extraModulePackages = [ config.boot.kernelPackages.hid-tmff2 ];
    boot.kernelModules = [ "hid-tmff-new" "hid-tminit-new" "usb-tminit-new" ];

    ## Upstream README: blacklist the in-tree initializer until the updated
    ## hid-tminit lands upstream. https://github.com/Kimplul/hid-tmff2
    boot.blacklistedKernelModules = [ "hid_thrustmaster" ];

    boot.extraModprobeConfig = lib.mkIf (cfg.timerMsecs != null) ''
      options hid-tmff-new timer_msecs=${toString cfg.timerMsecs}
    '';

    ## evdev-joystick / jstest / jscal, needed by the deadzone rule below.
    environment.systemPackages =
      [ pkgs.linuxConsoleTools ] ++ lib.optional cfg.oversteer pkgs.oversteer;

    services.udev.packages = lib.optional cfg.oversteer pkgs.oversteer;

    services.udev.extraRules = lib.mkIf cfg.deadzoneFix (
      lib.concatMapStringsSep "\n" (pid: ''
        SUBSYSTEM=="input", ATTRS{idVendor}=="044f", ATTRS{idProduct}=="${pid}", RUN+="${pkgs.linuxConsoleTools}/bin/evdev-joystick --evdev %E{DEVNAME} --deadzone 0"
      '') cfg.productIds
    );
  };
}
