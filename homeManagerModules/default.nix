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
    ./zen-browser
    ./brave
    # ./walker
    ./rofi
    ./git-accounts
    ./fish
    ./starship
    ./zellij
    ./zed
    ./jetbrains
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
  ## Try remove blur shadow on gtk dialogs
  stylix.targets.gtk = {
    extraCss = ''
      /* Disable client-side decorations on dialogs */
      dialog,
      .dialog,
      filechooser,
      .filechooser,
      window.dialog {
          box-shadow: none !important;
          backdrop-filter: none !important;
          filter: none !important;
      }

      /* Force removal of headerbar decorations */
      dialog headerbar,
      .dialog headerbar,
      filechooser headerbar,
      window.dialog headerbar {
          box-shadow: none !important;
          border: none !important;
          background: none !important;
          min-height: 0 !important;
          padding: 0 !important;
          margin: 0 !important;
      }

      /* Hide window controls in headerbar */
      dialog headerbar windowcontrols,
      .dialog headerbar windowcontrols,
      filechooser headerbar windowcontrols,
      window.dialog headerbar windowcontrols {
          display: none !important;
      }

      /* Remove titlebar */
      dialog .titlebar,
      .dialog .titlebar,
      filechooser .titlebar,
      window.dialog .titlebar {
          display: none !important;
      }
    '';
  };

  xdg.enable = true;
  home = {
    stateVersion = "25.05";
    packages = let
      stablePackages = with pkgs; [

        ## Hyprland must have
        hyprpaper # # Wallpaper manager
        hyprlock # # Lock screen
        hypridle # # Idle Manager
        hyprpolkitagent # # Polkit agent (GUI root access)
        wleave # # Logout Screen In Rust  (Using wlogout configuration)
        waybar # # Status bar
        hyprsysteminfo # # System hyprland GUI info
        swaynotificationcenter # # Notifications
        avizo # # Sound / brightness notifications
        walker # # App launcher
        rofi

        ## Clipboard management
        cliphist
        wl-clipboard

        ## Screenshotting
        grim # # Screenshot utils
        slurp # # Screenshot utils
        satty # # Screenshot tool

        ## Pipewire utils
        easyeffects # # Manage Inputs / Output for audio
        overskride # # Bluetooth App
        hyprpwcenter

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
        ## 2026-01-24 :: Updated version of kdePackages like Dolphin
        kdePackages.dolphin
        kdePackages.dolphin-plugins
        ## 2026-01-24 :: Removed theses
        # libsForQt5.dolphin
        # libsForQt5.dolphin-plugins

        ## TUI APP
        fastfetch
        gitui

        ## Monitoring
        htop
        btop
        zenith

        ripgrep
        git
        ## terminal editors
        vim
        neovim
        helix

        ## Terminals
        kitty
        ghostty

        # Email managers
        thunderbird

        bruno

        ## IDEs
        vscodium
        zed-editor
        nil # Nix language server for ZED
        nixd # Nix language server for ZED in Cpp

        mongodb-compass

        nushell
        fish
        bat
        zellij
        eza
        lsd
        fd
        # clean repositories
        kondo
        tokei
        yazi
        fzf
        ripgrep
        starship
        delta
        devenv
        direnv
        witr # Tool to get information for port

        slack

        vesktop
      ];
      unstablePackages =
        # builtins.trace "HomeManagerModue Unstable Packages content: ${(builtins.toJSON (builtins.attrNames unstable-nixpkgs ))}"
      [
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
