# fish

Configures the Fish shell.

## What it does

- Enables Fish via `programs.fish`
- Initialises Starship prompt (`starship init fish | source`)
- Clears the Fish greeting
- Enables direnv Fish integration (`programs.direnv.enableFishIntegration`)

## Shell aliases

| Alias | Expands to | Purpose |
|---|---|---|
| `ls` | `eza -lhF --icons -RT -L1 --hyperlink --group-directories-first --time-style="+%Y-%m-%d %H:%M" -m --git -rs size` | Rich directory listing with git status |
| `ll` | `ls -a` | Same as `ls` but includes hidden files |
| `cat` | `bat` | Syntax-highlighted file viewer |

## customConfigs dependencies

None — this module does not read from `customConfigs`.

## Notes

- Fish is declared as the user's default shell in `hosts/mastodant-1/users.nix`
- The `starship` module handles the actual prompt configuration
- `direnv` and `devenv` packages are declared in the global package list in `homeManagerModules/default.nix`
