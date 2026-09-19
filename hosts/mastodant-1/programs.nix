{ config, lib, pkgs, modulesPath, ... }@inputs: {

  # Install firefox.
  programs.firefox.enable = true;
  stylix.enable = true;
  ## Hyprland from nixpkgs rather than the upstream flake input (D7 in
  ## docs/HYPRLAND-LUA-MIGRATION.md). The flake input pinned 0.56.0 while
  ## home-manager's own default was nixpkgs 0.56.2, so two Hyprland builds sat in
  ## the closure and only one ever ran. Using nixpkgs for both aligns them on
  ## 0.56.2 — the patch release, with 16 backported fixes over 0.56.0 — and drops
  ## the input along with its aquamarine/hyprutils/hyprlang tree.
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.fish = {
    enable = true;
  };

  ## direnv with nix-direnv: replaces the builtin use_nix/use_flake with a
  ## persistent implementation that caches the evaluated environment and roots it
  ## against the GC, so re-entering a project directory does not re-evaluate.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

}