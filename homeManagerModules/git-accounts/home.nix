{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  cfg = config.programs.git-multi-account;
in
{
  config = lib.mkIf cfg.enable {
    # Git configuration
    programs.git = {
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

}