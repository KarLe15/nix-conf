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
        overskride                ## Bluetooth App 

        ## PDF viewer 
        zathura
        sioyek


        ## Games
        obs-studio 
        
        ## Image + Design
        gimp
        inkscape

        ## File explorer
        xfce.thunar
        xfce.thunar-volman
        xfce.thunar-archive-plugin
        xfce.thunar-media-tags-plugin
        nautilus
        nemo
        libsForQt5.dolphin
        libsForQt5.dolphin-plugins

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
      ];
    };
    
}
