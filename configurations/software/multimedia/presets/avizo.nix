{
  apply = { pkgs, ... }@inputs: {
    increaseVolume = {
      description = "Increase the Volume";
      command = "volumectl -M 0 -d -u up";
    };
    lowerVolume = {
      description = "Lower the Volume";
      command = "volumectl -M 0 -d -u down";
    };
    toggleVolume = {
      description = "Mute / Unmute the Volume";
      command = "volumectl -M 0 -d toggle-mute";
    };
    ## Microphone. avizo has no input control (volumectl/lightctl are output and
    ## backlight only), so these go straight to wpctl regardless of which OSD is
    ## active. -l 1.0 clamps to 100%: without it wpctl allows software boost.
    increaseMic = {
      description = "Increase the microphone volume";
      command = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+";
    };
    lowerMic = {
      description = "Lower the microphone volume";
      command = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%-";
    };
    toggleMic = {
      description = "Mute / Unmute the microphone";
      command = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
    };
  };
}