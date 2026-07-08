{ lib }:
let
  lib-types      = import ../../lib/types.nix { inherit lib; };
  ## Same shape as appDefType — aliased for domain clarity
  launcherDefType = lib-types.appDefType;
in
{
  launchersOutputType = lib.types.submodule {
    options = {
      applications = lib.mkOption { type = launcherDefType; };
      clipboard    = lib.mkOption { type = launcherDefType; };
    };
  };
}
