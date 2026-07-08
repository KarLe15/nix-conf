{ lib }:
{
  shellOutputType = lib.types.submodule {
    options = {
      aliases = lib.mkOption {
        type        = lib.types.attrsOf lib.types.str;
        description = "Shell aliases map (name -> command).";
      };
defaultPrompt = lib.mkOption {
        type = lib.types.submodule {
          options = {
            name = lib.mkOption {
              type        = lib.types.enum [ "starship" "oh-my-posh" ];
              description = "Prompt engine identifier.";
            };
            initCommand = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  fish = lib.mkOption { type = lib.types.str; description = "Init command for Fish."; };
                  bash = lib.mkOption { type = lib.types.str; description = "Init command for Bash."; };
                  zsh  = lib.mkOption { type = lib.types.str; description = "Init command for Zsh."; };
                };
              };
            };
          };
        };
      };
    };
  };
}
