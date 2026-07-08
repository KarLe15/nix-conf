{ lib }:
let
  mediaCommandType = lib.types.submodule {
    options = {
      description = lib.mkOption { type = lib.types.str; };
      command     = lib.mkOption { type = lib.types.str; };
    };
  };
in
{
  multimediaOutputType = lib.types.submodule {
    options = {
      increaseVolume = lib.mkOption { type = mediaCommandType; };
      lowerVolume    = lib.mkOption { type = mediaCommandType; };
      toggleVolume   = lib.mkOption { type = mediaCommandType; };
    };
  };
}
