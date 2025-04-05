{ pkgs, lib, config, ... } : {
  environment.systemPackages = with pkgs; [
    ## TODO :: 04/04/2025 :: Change this to be more reflecting of the reel config
    apple-cursor
    bibata-cursors
    ## https://github.com/catppuccin/cursors
    catppuccin-cursors.macchiatoDark
    catppuccin-cursors.macchiatoBlue
    nerd-fonts.jetbrains-mono
  ];

}