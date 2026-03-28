## =============================================================================
##  Profile: desktop-amd
##
##  AMD gaming/development desktop with a 3-monitor setup.
##  Currently used by: mastodant1 (hostname: karle)
## =============================================================================
{
  ## Hardware
  hardware.monitors.active          = "mastodant-3-screens";

  ## Style
  style.themes.active               = "catppuccin-macchiato";
  style.cursors.active              = "Bibata";
  style.fonts.active                = "mac-like";
  style.wallpaper.active            = "standard";
  style.statusbar.active            = "waybar-3-screen";
  style.workspaces.active           = "standard-3-screen";

  ## Software
  software.defaults.active          = "mastodant-1";
  software.developpement.active     = "opensource";
  software.git-accounts.active      = "standard";
  software.shortcuts.active         = "mastodant-1";
  software.launchers.active         = "rofi";
  software.powermanagement.active   = "systemD";
  software.multimedia.active        = "avizo";

  ## Feature flags
  software.modules.waybar.enable       = true;
  software.modules.git-accounts.enable = true;
  software.modules.eww.enable          = false;
  software.modules.walker.enable       = false;
}
