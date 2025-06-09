{
  apply = { pkgs, default-programs, ... }@inputs: {
    defaultEditor = default-programs.terminal-editor.command;
    enableAliases = false;
    git-accounts = [
      {
        username = "KarLe15";
        email = "leffadkarim97@live.fr";
        key = "/home/karim/.ssh/id_github_perso_ed25519";
        dns-alias = "github-perso";
        dns-origin = "github.com";
      }
      {
        username = "KarLe15";
        email = "leffadkarim97@live.fr";
        key = "/home/karim/.ssh/id_gitlab_perso_ed25519";
        dns-alias = "gitlab-perso";
        dns-origin = "gitlab.com";
      }
      {
        username = "KarLe15";
        email = "leffadkarim97@live.fr";
        key = "/home/karim/.ssh/id_gitlab_taneflit_ed25519";
        dns-alias = "gitlab-taneflit";
        dns-origin = "gitlab.com";
      }
    ];
  };
  autostart = [
  ];
}