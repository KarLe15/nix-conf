{inputs, pkgs, lib, config, ... }: 
let
  git-config-type-submodule = lib.types.submodule {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "Username for the git account";
      };
      
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address fior the git account";
      };
      
      key = lib.mkOption {
        type = lib.types.path;
        description = "Path to private Key";
      };

      dns-alias = lib.mkOption {
        type = lib.types.str;
        description = "Alias used for the SSH URL for the git account";
      };
      dns-origin = lib.mkOption {
        type = lib.types.str;
        description = "Alias used for the SSH URL for the git account";
      };
    };
  };
in {
  options.programs.git-multi-account = {
    enable = lib.mkEnableOption "Git multi-account management";
    git-accounts = lib.mkOption {
      type = lib.types.listOf git-config-type-submodule;
      default = [];
      description = "List of Git setup for keys";
    };
    defaultEditor = lib.mkOption {
      type = lib.types.str;
      default = "nano";
      description = "Default Git editor";
    };
    
    enableAliases = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable shell aliases for Git commands";
    };
  };
}