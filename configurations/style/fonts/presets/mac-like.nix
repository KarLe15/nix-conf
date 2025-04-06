{
  apply = {pkgs, ...}@inputs: { 
    # Use DZ font for Dotted Zero (Diff between 0 and O)
    mono = {
      group-name = "Meslo";
      exact-name = "MesloLGLDZ Nerd Font Mono";
      package = pkgs.nerd-fonts.meslo-lg;
    };
    serif = {
      group-name = "DejaVu";
      exact-name = "DejaVu Serif";
      package = pkgs.dejavu_fonts;
    };
    sansSerif = {
      group-name = "Meslo";
      exact-name = "MesloLGS Nerd Font";
      package = pkgs.nerd-fonts.meslo-lg;
    };
    emoji = {
      group-name = "Noto Emoji";
      exact-name = "Noto Color Emoji";
      package = pkgs.noto-fonts-emoji;
    };
  };

  autostart = [
  ];
}