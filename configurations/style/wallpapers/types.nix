{ lib }:
{
  wallpaperOutputType = lib.types.submodule {
    options = {
      default = lib.mkOption {
        type = lib.types.submodule {
          options = {
            path = lib.mkOption {
              type        = lib.types.path;
              description = "Absolute path to the wallpaper image file.";
            };
          };
        };
      };
    };
  };
}
