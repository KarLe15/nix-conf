{ lib }:
{
  themesOutputType = lib.types.submodule {
    options = {
      base16-schemes-yaml = lib.mkOption {
        type        = lib.types.path;
        description = "Path to a base16-compatible YAML color scheme file.";
      };
      flavor = lib.mkOption {
        type        = lib.types.str;
        description = "Catppuccin flavor name (latte, frappe, macchiato, mocha).";
      };
      polarity = lib.mkOption {
        type        = lib.types.enum [ "light" "dark" ];
        description = ''
          Light/dark preference for the scheme, published as stylix.polarity.
          Drives the gsettings color-scheme key, which xdg-desktop-portal exposes
          as org.freedesktop.appearance, i.e. prefers-color-scheme in browsers.
        '';
      };
    };
  };
}
