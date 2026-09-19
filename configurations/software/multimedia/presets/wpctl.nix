## PipeWire multimedia controls via wpctl (wireplumber), with no OSD of its own —
## the Quickshell OSD reacts to the PipeWire properties instead, so a change from
## any source (these keys, pavucontrol, an application) raises it.
##
## `-l 1.0` clamps to 100%. Without it wpctl allows software boost: from 0.98 a
## `5%+` lands on 1.03. The design specifies "clamped 0-100%, no software boost".
##
## Note: unlike avizo's `volumectl -u`, changing the volume does NOT unmute. The
## OSD shows the level greyed while muted, so the state stays visible.
{
  apply = { pkgs, ... }@inputs: {
    increaseVolume = {
      description = "Increase the Volume";
      command = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
    };
    lowerVolume = {
      description = "Lower the Volume";
      command = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-";
    };
    toggleVolume = {
      description = "Mute / Unmute the Volume";
      command = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    };

    ## Microphone — bound inside the `multimedia` submap.
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
