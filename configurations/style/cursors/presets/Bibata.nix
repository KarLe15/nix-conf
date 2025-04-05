{
  apply = {pkgs, ...}@inputs: { 
    default = {
      group-name = "Bibata";
      size = 24;
      exact-name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  autostart = [
  ];
}