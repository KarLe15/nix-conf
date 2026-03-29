{inputs, pkgs, lib, config, customConfigs, ... } :
let
  enabled = customConfigs.softwareConfigs.modules.git-accounts.enable;
  generateSSHBlock = gitConfig: {
    name = gitConfig.dns-alias;
    value = {
      hostname = gitConfig.dns-origin;
      user = "git";
      identityFile = gitConfig.key;
      identitiesOnly = true;
      addKeysToAgent = "yes";
    };
  };
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
        ##=========================================================
        ## Update 2026-01-24 :
        #   - Convert the generation `generateSSHBlock` from generating String into typesafe Nix
        #
        #   - Explicitly add the usage of default behaviour on SSH
        #     Host *
        #       ServerAliveInterval 60
        #       ServerAliveCountMax 3
        ##=========================================================
        enable = true;
        enableDefaultConfig = false;
        matchBlocks =
          (builtins.listToAttrs (map generateSSHBlock cfg.git-accounts))
          // {
            "*" = {
              serverAliveInterval = 60;
              serverAliveCountMax = 3;
            };
          };

      };
      git = {
        enable = true;
        ## Update 2026-01-24 :: programs.git.extraConfig -> programs.git.settings
        settings = {
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
