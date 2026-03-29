{ lib }:
let
  lib-types  = import ../../lib/types.nix { inherit lib; };
  appDefType = lib-types.appDefType;
  appDefWithEnvType = lib-types.appDefWithEnvType;
in
{
  defaultsOutputType = lib.types.submodule {
    options = {
      browser             = lib.mkOption { type = appDefType; };
      terminal            = lib.mkOption { type = appDefType; };
      terminal-editor     = lib.mkOption { type = appDefType; };
      file-explorer       = lib.mkOption { type = appDefType; };
      email               = lib.mkOption { type = appDefType; };
      notification-center = lib.mkOption { type = appDefType; };
      logout              = lib.mkOption { type = appDefWithEnvType; };
      lockscreen          = lib.mkOption { type = appDefType; };
      idlemanager         = lib.mkOption { type = appDefType; };
      audiomanager        = lib.mkOption { type = appDefType; };
    };
  };
}
