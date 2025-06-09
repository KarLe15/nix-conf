{config, lib, pkgs, inputs, ... } : {
    
    imports = [
      ./catppuccin
      ./hyprland
      ./hyprlock
      ./hypridle
      ./hyprpolkitagent
      ./swaync
      ./avizo
      ./wlogout
      ./ghostty
      ./waybar
      ./eww
      ./walker
      ./git-accounts
    ];

    stylix.targets.gitui.enable = true;
    stylix.autoEnable = true;
    
    xdg.enable = true;
    home = {
      stateVersion = "24.11";
      packages = with pkgs; [
        
        # eww
        ## Hyprland must have 
        hyprpaper                 ## Wallpaper manager
        hyprlock                  ## Lock screen
        hypridle                  ## Idle Manager
        hyprpolkitagent           ## Polkit agent (GUI root access)
        wleave                    ## Logout Screen In Rust  (Using wlogout configuration)
        waybar                    ## Status bar
        hyprsysteminfo            ## System hyprland GUI info
        swaynotificationcenter    ## Notifications
        avizo                     ## Sound / brightness notifications
        walker                    ## App launcher
        
        ## Screenshotting
        grim                      ## Screenshot utils
        slurp                     ## Screenshot utils
        satty                     ## Screenshot tool


        ## Pipewire utils
        easyeffects               ## Manage Inputs / Output for audio

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
