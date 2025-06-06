rec {
  mod = "ALT";
  mod-shift = "ALT_SHIFT";
  secondary = "SUPER";
  secondary-shift = "SUPER_SHIFT";
  shortcuts-definition = {defaults, developpement, launchers, pkgs, ...}@programs: [
    ## ===========================<     WM Commands    >==========================
    {
      description = "Close Active Window";
      mod1 = secondary;
      key = "Q";
      command = "";
      dispatcher-type = "killactive";
      env = "";
    }
    {
      description = "Force Close Active Window";
      mod1 = secondary-shift;
      key = "Q";
      command = "";
      dispatcher-type = "forcekillactive";
      env = "";
    }
    {
      description = "FullScreen Active Window (False full screen (with BAR))";
      mod1 = mod;
      key = "F";
      command = "1";
      dispatcher-type = "fullscreen";
      env = "";
    }
    {
      description = "FullScreen Active Window (True full screen (without BAR))";
      mod1 = mod-shift;
      key = "F";
      command = "0";
      dispatcher-type = "fullscreen";
      env = "";
    }
    {
      description = "Open Notification Center";
      mod1 = mod-shift;
      key = "N";
      command = defaults.notification-center.command;
      dispatcher-type = "exec";
      env = "";
    }
    ## ===========================<  Locking Commands  >==========================
    {
      description = "Logout Screen";
      mod1 = secondary;
      key = "L";
      command = defaults.logout.command;
      dispatcher-type = "exec";
      # FIXME :: 05/05/2025 :: Add this to fix Wlogout / Wleave issue with icons
      env = defaults.logout.env;
    }
    ## ===========================<  Launchers Manage  >==========================
    {
      description = "Application launcher";
      mod1 = mod;
      key = "Space";
      command = launchers.applications.command;
      dispatcher-type = "exec";
      env = "";
    }
    ## ===========================<  Default programs  >==========================
    {
      description = "Open File Explorer";
      mod1 = mod;
      key = "E";
      command = defaults.file-explorer.command;
      dispatcher-type = "exec";
      env = "";
    }
    {
      description = "Open Terminal";
      mod1 = mod;
      key = "T";
      command = defaults.terminal.command;
      dispatcher-type = "exec";
      env = "";
    }
    {
      description = "Open Browser";
      mod1 = mod;
      key = "B";
      command = defaults.browser.command;
      dispatcher-type = "exec";
      env = "";
    }
  ];
}