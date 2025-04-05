{
  apply = { pkgs, ... }@inputs: {
    apiClient = {
      command = "bruno";
      name = "Bruno";
      package = pkgs.bruno;
    };
  };
  autostart = [
  ];
}