{
  apply = { pkgs, ... }@inputs: {
    applications = {
      command = "walker";
      name = "Walker App Launcher";
      package = pkgs.wallpapers;
    };
  };
  autostart = [
    "walker --gapplication-service"
  ];
}