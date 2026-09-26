{ pkgs, lib, config, ragenix, ragenixKeyPath, system, ... } : {
  environment.systemPackages = with pkgs; [
      ragenix.packages.${system}.default
  ];
  age.identityPaths = [ ragenixKeyPath ];
  age.secrets = let
    ##=========================================================
    ## Update 2026-09-26 :
    #   - SSH private keys are consumed straight out of `age.secretsDir`
    #     (/run/agenix/<name>); the git-accounts preset points `key` there
    #     instead of at hand-placed copies under ~/.ssh. Activation
    #     re-decrypts them on every switch and every boot, so a from-scratch
    #     machine only needs the agenix identity to get every account key.
    #
    #   - owner/group/mode are mandatory: the defaults are root:root 0400,
    #     which the user's ssh client cannot read. Plaintext stays on the
    #     /run/agenix.d ramfs and never touches persistent storage.
    ##=========================================================
    sshKey = file: {
      inherit file;
      owner = "karim";
      group = "users";
      mode  = "0600";
    };
  in {
    "github-perso"                        = sshKey ../../secrets_store/github-perso.age;
    "github-perso.passphrase".file        = ../../secrets_store/github-perso.passphrase.age;
    "gitlab-perso"                        = sshKey ../../secrets_store/gitlab-perso.age;
    "gitlab-perso.passphrase".file        = ../../secrets_store/gitlab-perso.passphrase.age;
    "gitlab-taneflit"                     = sshKey ../../secrets_store/gitlab-taneflit.age;
    "gitlab-taneflit.passphrase".file     = ../../secrets_store/gitlab-taneflit.passphrase.age;
    "gitlab-nexo"                         = sshKey ../../secrets_store/gitlab-nexo.age;
  };
}
