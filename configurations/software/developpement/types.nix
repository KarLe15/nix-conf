{ lib }:
let
  lib-types  = import ../../lib/types.nix { inherit lib; };
  appDefType = lib-types.appDefType;
in
{
  developpementOutputType = lib.types.submodule {
    options = {
      apiClient = lib.mkOption { type = appDefType; };
    };
  };
}
