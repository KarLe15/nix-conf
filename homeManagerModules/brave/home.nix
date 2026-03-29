{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.brave;
in {
  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable   = true;
      package  = pkgs.brave;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      ];
      commandLineArgs = [
        "--disable-features=WebRtcAllowInputVolumeAdjustment"
      ];
    };
  };
}
