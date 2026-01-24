

{inputs, pkgs, lib, config, customConfigs, ... } :
let
in
{
  # Looked up from https://www.reddit.com/r/NixOS/comments/1bqilmi/how_to_configure_brave_browser_package_to_install/?show=original
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
    ];
    commandLineArgs = [
      "--disable-features=WebRtcAllowInputVolumeAdjustment"
    ];
  };
}
