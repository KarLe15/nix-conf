{config, lib, pkgs, inputs, ... } : {
    
    imports = [
      ./hyprland
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
        walker
        gitui

        htop
        btop
        zenith
        ripgrep
        git
        vim
        neovim
        kitty
        ghostty
        nautilus
        thunderbird
        bruno
        fastfetch
        vscodium
      ];
    };
    
}
