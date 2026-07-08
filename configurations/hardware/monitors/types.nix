{ lib }:
let
  positionType = lib.types.submodule {
    options = {
      x = lib.mkOption { type = lib.types.int; };
      y = lib.mkOption { type = lib.types.int; };
    };
  };

  monitorDefType = lib.types.submodule {
    options = {
      name        = lib.mkOption { type = lib.types.str; description = "Kernel device name, e.g. \"HDMI-A-2\"."; };
      width       = lib.mkOption { type = lib.types.int; };
      height      = lib.mkOption { type = lib.types.int; };
      refreshRate = lib.mkOption { type = lib.types.int; };
      position    = lib.mkOption { type = positionType; };
      ## Accept int (e.g. 1) or float (e.g. 1.5) — Nix integer literals satisfy
      ## neither lib.types.float nor lib.types.number on some nixpkgs versions,
      ## so we explicitly allow either.
      scale       = lib.mkOption { type = lib.types.either lib.types.int lib.types.float; };
      primary     = lib.mkOption { type = lib.types.bool; default = false; };
    };
  };
in
{
  monitorsOutputType = lib.types.submodule {
    options = {
      definition = lib.mkOption {
        type        = lib.types.listOf monitorDefType;
        description = "Ordered list of monitor configuration records.";
      };
      disposition = lib.mkOption {
        type = lib.types.submodule {
          options = {
            code     = lib.mkOption { type = lib.types.str; description = "Monitor name for code/IDE workspaces."; };
            terminal = lib.mkOption { type = lib.types.str; description = "Monitor name for terminal workspaces."; };
            browser  = lib.mkOption { type = lib.types.str; description = "Monitor name for browser workspaces."; };
          };
        };
      };
    };
  };
}
