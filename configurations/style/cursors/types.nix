{ lib }:
let
  cursorDefType = lib.types.submodule {
    options = {
      group-name = lib.mkOption { type = lib.types.str; };
      exact-name = lib.mkOption {
        type        = lib.types.str;
        description = "Exact cursor theme name passed to hyprctl setcursor.";
      };
      size    = lib.mkOption { type = lib.types.int; };
      package = lib.mkOption { type = lib.types.package; };
    };
  };
in
{
  cursorsOutputType = lib.types.submodule {
    options = {
      default = lib.mkOption { type = cursorDefType; };
    };
  };
}
