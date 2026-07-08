{
  apply = { pkgs, ... }: {
    defaultPrompt = {
      name = "starship";
      initCommand = {
        fish = "starship init fish | source";
        bash = ''eval "$(starship init bash)"'';
        zsh  = ''eval "$(starship init zsh)"'';
      };
    };
    aliases = {
      ls  = ''eza -lhF --icons -RT -L1 --hyperlink --group-directories-first --time-style="+%Y-%m-%d %H:%M" -m --git -rs size'';
      ll  = "ls -a";
      cat = "bat";
    };
  };

  autostart = [];
}
