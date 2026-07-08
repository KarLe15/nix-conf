## =============================================================================
##  Flat type aggregator
##
##  Imports all domain types.nix files and re-exports them as a single
##  attribute set.  This is the only file custom-config-generator.nix
##  needs to import.
##
##  Domain types live at:
##    configurations/<domain>/<sub-domain>/types.nix
##
##  Shared primitive types (packageType, appDefType, appDefWithEnvType) live at:
##    configurations/lib/types.nix
## =============================================================================
{ lib }:
let
  monitors      = import ./hardware/monitors/types.nix      { inherit lib; };
  themes        = import ./style/themes/types.nix            { inherit lib; };
  fonts         = import ./style/fonts/types.nix             { inherit lib; };
  cursors       = import ./style/cursors/types.nix           { inherit lib; };
  wallpapers    = import ./style/wallpapers/types.nix        { inherit lib; };
  defaults      = import ./software/defaults/types.nix       { inherit lib; };
  launchers     = import ./software/launchers/types.nix      { inherit lib; };
  multimedia    = import ./software/multimedia/types.nix     { inherit lib; };
  powermgmt     = import ./software/powermanagement/types.nix { inherit lib; };
  developpement = import ./software/developpement/types.nix  { inherit lib; };
  gitAccounts   = import ./software/git-accounts/types.nix   { inherit lib; };
  shell           = import ./software/shell/types.nix            { inherit lib; };
  waylandDesktop  = import ./software/wayland-desktop/types.nix { inherit lib; };
in
  monitors
  // themes
  // fonts
  // cursors
  // wallpapers
  // defaults
  // launchers
  // multimedia
  // powermgmt
  // developpement
  // gitAccounts
  // shell
  // waylandDesktop
