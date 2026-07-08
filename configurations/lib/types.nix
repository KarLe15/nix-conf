## =============================================================================
##  Shared primitive types
##
##  Types used across multiple domains.  Domain-specific types live alongside
##  their domain in configurations/<domain>/<sub-domain>/types.nix.
## =============================================================================
{ lib }:
{
  ## A derivation / store path
  packageType = lib.types.package;

  ## { command, name, package }
  appDefType = lib.types.submodule {
    options = {
      command = lib.mkOption {
        type = lib.types.str;
        description = "Shell command to launch the application.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable display name.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        description = "nixpkgs derivation that provides the command.";
      };
    };
  };

  ## { command, name, package, env }  (logout has an extra env field)
  appDefWithEnvType = lib.types.submodule {
    options = {
      command = lib.mkOption { type = lib.types.str; };
      name    = lib.mkOption { type = lib.types.str; };
      package = lib.mkOption { type = lib.types.package; };
      env     = lib.mkOption {
        type    = lib.types.str;
        default = "";
        description = "Optional env-var prefix prepended to the exec command.";
      };
    };
  };
}
