{
  apply = {pkgs, ... }@inputs: {
    base16-schemes-yaml = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
  };
  autostart = [
  ];
}