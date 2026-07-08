{
  config,
  lib,
  pkgs,
  inputs,
  unstable-nixpkgs,
  ...
}:
{

  imports = [
    ./catppuccin
    ./hyprland
    ./hyprlock
    ./hypridle
    ./hyprpolkitagent
    ./swaync
    ./avizo
    ./wlogout
    ./wleave
    ./ghostty
    ./waybar
    # ./zen-browser # removed due to compilation error
    ./brave
    ./rofi
    ./git-accounts
    ./fish
    ./starship
    ./zellij
    ./zed
    ./jetbrains
    ./wayland-desktop
  ];

  stylix.targets.gitui.enable = true;
  stylix.targets.bat.enable = true;
  programs.bat.enable = true;
  stylix.targets.yazi.enable = true;
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };
  stylix.autoEnable = true;

  xdg.enable = true;
  home = {
    stateVersion = "25.05";
    packages = let
      stablePackages = with pkgs; [

        bitwarden-desktop
        ## PDF viewer
        zathura
        sioyek

        ## Games
        obs-studio

        ## Image + Design
        gimp
        inkscape

        ## File explorer
        ## 2026-01-24 :: evaluation warning: ‘xfce.thunar’ was moved to top-level. Please use ‘pkgs.thunar’ directly
        thunar
        thunar-volman
        thunar-archive-plugin
        thunar-media-tags-plugin
        nautilus
        nemo
        kdePackages.dolphin
        kdePackages.dolphin-plugins

        ## TUI APP
        fastfetch
        gitui

        ## Monitoring
        htop
        btop
        zenith

        git
        ## terminal editors
        vim
        neovim
        helix

        ## Terminals
        kitty

        # Email managers
        thunderbird

        bruno

        ## IDEs
        vscodium
        nil # Nix language server for ZED
        nixd # Nix language server for ZED in Cpp

        mongodb-compass

        nushell
        eza
        lsd
        fd
        # clean repositories
        kondo
        tokei
        fzf
        ripgrep
        delta
        devenv
        direnv
        witr # Tool to get information for port

        slack

        vesktop
        vlc
      ];
      unstablePackages = [
        # Ollama
        unstable-nixpkgs.ollama-rocm ## AMD acceleration for Ollama
        # Other Impl GPU acceleration
        # ollama-vulkan
        # ollama-cpu
        # ollama-cuda
        ## LLM tools :
        unstable-nixpkgs.opencode
        unstable-nixpkgs.claude-code
        unstable-nixpkgs.claude-monitor
        unstable-nixpkgs.spec-kit # Spec driven developpment # https://github.com/github/spec-kit
      ];
    in
    stablePackages ++ unstablePackages;
  };

}
