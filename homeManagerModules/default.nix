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

    programs.git-multi-account = {
      enable = true;
      git-accounts = [
        {
          username = "KarLe15";
          email = "leffadkarim97@live.fr";
          key = "/home/karim/.ssh/id_github_perso_ed25519";
          dns-alias = "github-perso";
          dns-origin = "github.com";
        }
        {
          username = "KarLe15";
          email = "leffadkarim97@live.fr";
          key = "/home/karim/.ssh/id_gitlab_perso_ed25519";
          dns-alias = "gitlab-perso";
          dns-origin = "gitlab.com";
        }
        {
          username = "KarLe15";
          email = "leffadkarim97@live.fr";
          key = "/home/karim/.ssh/id_gitlab_taneflit_ed25519";
          dns-alias = "gitlab-taneflit";
          dns-origin = "gitlab.com";
        }
      ];
    };
    
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
