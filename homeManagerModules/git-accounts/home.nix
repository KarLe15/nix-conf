{inputs, pkgs, lib, config, customConfigs, ... } : 
let 
  enabled = customConfigs.softwareConfigs.modules.git-accounts.enable;
  generateSSHBlock = gitConfig: ''
     Host ${gitConfig.dns-alias}
        HostName ${gitConfig.dns-origin}
        User git
        IdentityFile ${gitConfig.key}
        IdentitiesOnly yes
        AddKeysToAgent yes
  '';
in
{
  config = lib.mkIf enabled {
    programs = let
      default-programs = customConfigs.softwareConfigs.defaults.apply {inherit pkgs; };
      cfg = customConfigs.softwareConfigs.git-accounts.apply {
        inherit pkgs default-programs;
      }; 
    in {
      ssh = {
        enable = true;
        extraConfig = lib.concatMapStrings generateSSHBlock cfg.git-accounts;
      };
      git = {
        enable = true;
        extraConfig = {
          init = {
            defaultBranch = "main";
            templateDir = "~/.git-template";
          };
          core = {
            editor = cfg.defaultEditor;
            autocrlf = false;
          };
          pull.rebase = true;
          push = {
            default = "simple";
            autoSetupRemote = true;
          };
          transfer.fsckobjects = true;
          fetch.fsckobjects = true;
          receive.fsckObjects = true;
        };
      };
    };
  };

}