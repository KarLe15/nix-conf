{ config, lib, pkgs, modulesPath, ... }: {

  # Install firefox.
  programs.firefox.enable = true;
  stylix.enable = true;
  programs.hyprland.enable = true;
  # programs.hyprland.package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

}