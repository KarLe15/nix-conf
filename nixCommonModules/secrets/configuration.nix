{ pkgs, lib, config, ragenix, ragenixKeyPath, system, ... } : {
  environment.systemPackages = with pkgs; [
      ragenix.packages.${system}.default
  ];
  age.identityPaths = [ ragenixKeyPath ];
  age.secrets = {
    "github-perso".file                   = ../../secrets_store/github-perso.age;
    "github-perso.passphrase".file        = ../../secrets_store/github-perso.passphrase.age;
    "gitlab-perso".file                   = ../../secrets_store/gitlab-perso.age;
    "gitlab-perso.passphrase".file        = ../../secrets_store/gitlab-perso.passphrase.age;
    "gitlab-taneflit".file                = ../../secrets_store/gitlab-taneflit.age;
    "gitlab-taneflit.passphrase".file     = ../../secrets_store/gitlab-taneflit.passphrase.age;
  }; 
}