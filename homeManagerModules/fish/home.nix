

{inputs, pkgs, lib, config, customConfigs, ... } : 
let 
in
{
  programs.direnv = {
    enableFishIntegration = true;
  };
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Initialize starship
      starship init fish | source
      
      # Set fish as login shell
      set -U fish_greeting ""
    '';
    shellAliases = {
      ls = "eza -lhF --icons -RT -L1 --hyperlink --group-directories-first --time-style=\"+%Y-%m-%d %H:%M\" -m --git -rs size";
      ll = "ls -a";
      cat = "bat";
    };
  };
}
