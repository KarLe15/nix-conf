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
  software.shell.active             = "standard";

  ## Feature flags
  # # Themes
  software.modules.catppuccin.enable      = true;
  # Window Manager
  software.modules.waybar.enable          = true;
  software.modules.swaync.enable          = true;
  software.modules.avizo.enable           = true;
  software.modules.hypridle.enable        = true;
  software.modules.hyprlock.enable        = true;
  software.modules.hyprpolkitagent.enable = true;
  # Logout
  software.modules.wlogout.enable         = false;
  software.modules.wleave.enable          = true;
  # App search
  software.modules.rofi.enable            = true;
  software.modules.walker.enable          = false;
  # IDE
  software.modules.jetbrains.enable       = true;
  software.modules.zed.enable             = true;
  # Browsers
  software.modules.brave.enable           = true;
  software.modules.zen-browser.enable     = true;
  # Terminal / Shell
  software.modules.ghostty.enable         = true;
  software.modules.starship.enable        = true;
  software.modules.fish.enable            = true;
  software.modules.hyprland.enable        = true;
  software.modules.git-accounts.enable    = true;
  software.modules.zellij.enable          = true;
}
