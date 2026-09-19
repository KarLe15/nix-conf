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
      # Output (speaker) controls.
      increaseVolume = lib.mkOption { type = mediaCommandType; };
      lowerVolume    = lib.mkOption { type = mediaCommandType; };
      toggleVolume   = lib.mkOption { type = mediaCommandType; };

      # Input (microphone) controls. Bound inside the `multimedia` submap, where
      # the same XF86Audio keys target the mic instead of the speaker.
      increaseMic    = lib.mkOption { type = mediaCommandType; };
      lowerMic       = lib.mkOption { type = mediaCommandType; };
      toggleMic      = lib.mkOption { type = mediaCommandType; };
    };
  };
}
