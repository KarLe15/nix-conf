## =============================================================================
##  Profile system
##
##  A profile is a named bundle of preset selections and feature flags for a
##  machine archetype.  Each host selects one profile in its options.nix, then
##  overrides only what differs from the profile defaults.
##
##  All profile values are applied with `lib.mkDefault`, so any option set
##  directly in a host's options.nix takes precedence without needing mkForce.
##
##  To add a new profile:
##    1. Create configurations/profiles/presets/<name>.nix
##    2. Add the name to the enum list below
## =============================================================================
{ lib, config, ... }:
let
  profile = import ./presets/${config.profile.active}.nix;
in
{
  options.profile = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "desktop-amd"
      ];
      description = ''
        Machine archetype profile name.  The selected profile supplies
        lib.mkDefault values for all preset selectors and feature flags.
        Individual options in the host's options.nix override the profile.

        Available profiles:
          desktop-amd  AMD gaming/development desktop, 3-monitor setup
      '';
    };
  };

  config = {
    ## Hardware
    hardware.monitors.active        = lib.mkDefault profile.hardware.monitors.active;

    ## Style
    style.themes.active             = lib.mkDefault profile.style.themes.active;
    style.cursors.active            = lib.mkDefault profile.style.cursors.active;
    style.fonts.active              = lib.mkDefault profile.style.fonts.active;
    style.wallpaper.active          = lib.mkDefault profile.style.wallpaper.active;
    style.statusbar.active          = lib.mkDefault profile.style.statusbar.active;
    style.workspaces.active         = lib.mkDefault profile.style.workspaces.active;

    ## Software presets
    software.defaults.active        = lib.mkDefault profile.software.defaults.active;
    software.developpement.active   = lib.mkDefault profile.software.developpement.active;
    software.git-accounts.active    = lib.mkDefault profile.software.git-accounts.active;
    software.shortcuts.active       = lib.mkDefault profile.software.shortcuts.active;
    software.launchers.active       = lib.mkDefault profile.software.launchers.active;
    software.powermanagement.active = lib.mkDefault profile.software.powermanagement.active;
    software.multimedia.active      = lib.mkDefault profile.software.multimedia.active;

    ## Feature flags
    software.modules.waybar.enable       = lib.mkDefault profile.software.modules.waybar.enable;
    software.modules.git-accounts.enable = lib.mkDefault profile.software.modules.git-accounts.enable;
  };
}
