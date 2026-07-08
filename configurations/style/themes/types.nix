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
    };
  };
}
