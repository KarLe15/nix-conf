{ lib }:
let
  lib-types = import ../../lib/types.nix { inherit lib; };
in
{
  waylandDesktopOutputType = lib.types.submodule {
    options = {
      wallpaper = lib.mkOption {
        type        = lib.types.listOf lib-types.packageType;
        description = "Wallpaper management packages.";
      };
      clipboard = lib.mkOption {
        type        = lib.types.listOf lib-types.packageType;
        description = "Clipboard management packages.";
      };
      screenshot = lib.mkOption {
        type        = lib.types.listOf lib-types.packageType;
        description = "Screenshot toolchain packages.";
      };
      extra = lib.mkOption {
        type        = lib.types.listOf lib-types.packageType;
        default     = [];
        description = "Additional Wayland desktop packages.";
      };
    };
  };
}
