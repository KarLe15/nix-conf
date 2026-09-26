{
  apply = { pkgs, default-programs, ... }@inputs: {
    defaultEditor = default-programs.terminal-editor.command;
    enableAliases = false;
    git-accounts = [
      {
        username = "KarLe15";
        email = "leffadkarim97@live.fr";
        key = "/run/agenix/github-perso";
        dns-alias = "github-perso";
        dns-origin = "github.com";
      }
      {
        username = "KarLe15";
        email = "leffadkarim97@live.fr";
        key = "/run/agenix/gitlab-perso";
        dns-alias = "gitlab-perso";
        dns-origin = "gitlab.com";
      }
      {
        username = "KarLe15";
        email = "leffadkarim97@live.fr";
        key = "/run/agenix/gitlab-taneflit";
        dns-alias = "gitlab-taneflit";
        dns-origin = "gitlab.com";
      }
      {
        username = "KarLeNexo";
        email = "karim.leffad@nexoriha.com";
        key = "/run/agenix/gitlab-nexo";
        dns-alias = "gitlab-nexo";
        dns-origin = "gitlab.com";
      }
    ];
  };
  autostart = [
  ];
}
