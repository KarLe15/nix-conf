{ lib }:
let
  gitAccountDefType = lib.types.submodule {
    options = {
      username   = lib.mkOption { type = lib.types.str; };
      email      = lib.mkOption { type = lib.types.str; };
      key        = lib.mkOption { type = lib.types.path; description = "Path to SSH private key."; };
      dns-alias  = lib.mkOption { type = lib.types.str; description = "SSH Host alias, e.g. \"github-perso\"."; };
      dns-origin = lib.mkOption { type = lib.types.str; description = "Real SSH hostname, e.g. \"github.com\"."; };
    };
  };
in
{
  gitAccountsOutputType = lib.types.submodule {
    options = {
      defaultEditor = lib.mkOption { type = lib.types.str; };
      enableAliases = lib.mkOption { type = lib.types.bool; default = false; };
      git-accounts  = lib.mkOption { type = lib.types.listOf lib.types.attrs; };
    };
  };
}
