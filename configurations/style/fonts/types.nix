{ lib }:
let
  fontDefType = lib.types.submodule {
    options = {
      group-name = lib.mkOption {
        type        = lib.types.str;
        description = "Font family name.";
      };
      exact-name = lib.mkOption {
        type        = lib.types.str;
        description = "Exact PostScript font name passed to Stylix / fontconfig.";
      };
      package = lib.mkOption { type = lib.types.package; };
    };
  };
in
{
  fontsOutputType = lib.types.submodule {
    options = {
      mono      = lib.mkOption { type = fontDefType; };
      serif     = lib.mkOption { type = fontDefType; };
      sansSerif = lib.mkOption { type = fontDefType; };
      emoji     = lib.mkOption { type = fontDefType; };
    };
  };
}
