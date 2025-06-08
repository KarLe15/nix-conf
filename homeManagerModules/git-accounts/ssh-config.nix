{inputs, pkgs, lib, config, ... }: 
let 
  cfg = config.programs.git-multi-account;
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
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      extraConfig = lib.concatMapStrings generateSSHBlock cfg.git-accounts;
    };

  };
}