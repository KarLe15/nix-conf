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
  };
}