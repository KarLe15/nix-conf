{ lib, ... }: {
  ## ===============================<  HARDWARE  >==========================================
  hardware.monitors.active = "mastodant-3-screens";

  ## ===============================<    STYLE   >==========================================
  style.themes.active = "catppuccin-macchiato";
  style.cursors.active = "Bibata";
  style.fonts.active = "mac-like";
  style.wallpaper.active = "standard";
  style.statusbar.active = "waybar-3-screen";
  style.workspaces.active = "standard-3-screen";

  ## ===============================<  Software  >==========================================
  software.defaults.active = "mastodant-1";
  software.developpement.active = "opensource";
  software.git-accounts.active = "standard";
  software.shortcuts.active = "mastodant-1";
  software.launchers.active = "walker";
  software.powermanagement.active = "systemD";
  software.multimedia.active = "avizo";

  ## ===============================<   stylix   >==========================================
  stylix.targets.qt.platform = lib.mkForce "qtct";
}