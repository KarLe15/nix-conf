{ config, lib, pkgs, modulesPath, hyprland, ... }@inputs: {

  # Install firefox.
  programs.firefox.enable = true;
  stylix.enable = true;
  programs.hyprland = builtins.trace "HomeManagerModue content: ${(builtins.toJSON (builtins.attrNames inputs ))}" {
    enable = true;
    package = hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.fish = {
    enable = true;
  };
  # programs.hyprland.package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

}