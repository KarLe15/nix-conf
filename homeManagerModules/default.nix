{config, lib, pkgs, inputs, ... } : {
    
    imports = [
      ./hyprland
      ./hyprlock
      ./ghostty
      ./eww
      ./walker
    ];

    stylix.targets.gitui.enable = true;
    stylix.autoEnable = true;

    xdg.enable = true;
    home = {
      stateVersion = "24.11";
      packages = with pkgs; [
        ## Hyprland must have 
        # eww
        hyprpaper  ## Wallpaper manager
        hyprlock   ## Lock screen
        wleave     ## Logout Screen In Rust 
        hyprsysteminfo ## System hyprland GUI info
        walker     ## App launcher
        grim       ## Screenshot utils
        slurp      ## Screenshot utils
        satty      ## Screenshot tool


        ## Pipewire utils
        easyeffects

        ## Games
        obs-studio 
        
        ## TUI APP
        fastfetch
        gitui
        htop
        btop
        zenith
        ripgrep
        git
        vim
        neovim

        ## Terminals
        kitty
        ghostty

        ## File Explorer
        nautilus
        thunderbird
        
        bruno
        
        ## IDEs
        vscodium
      ];
    };
    
}
