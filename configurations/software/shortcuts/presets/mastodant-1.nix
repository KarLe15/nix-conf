rec {
  mod = "ALT";
  mod-shift = "ALT_SHIFT";
  secondary = "SUPER";
  secondary-shift = "SUPER_SHIFT";
  shortcuts-definition = {defaults, developpement, launchers, ...}@programs: [
    ## ===========================<     WM Commands    >==========================
    {
      description = "Close Active Window";
      mod1 = secondary;
      key = "Q";
      command = "";
      dispatcher-type = "killactive";
    }
    {
      description = "Force Close Active Window";
      mod1 = secondary-shift;
      key = "Q";
      command = "";
      dispatcher-type = "forcekillactive";
    }
    {
      description = "FullScreen Active Window (False full screen (with BAR))";
      mod1 = mod;
      key = "F";
      command = "1";
      dispatcher-type = "fullscreen";
    }
    {
      description = "FullScreen Active Window (True full screen (without BAR))";
      mod1 = mod-shift;
      key = "F";
      command = "0";
      dispatcher-type = "fullscreen";
    }
    ## ===========================<  Launchers Manage  >==========================
    {
      description = "FullScreen Active Window (True full screen (without BAR))";
      mod1 = mod;
      key = "Space";
      command = launchers.applications.command;
      dispatcher-type = "exec";
    }
    ## ===========================<  Default programs  >==========================
    {
      description = "Open File Explorer";
      mod1 = mod;
      key = "E";
      command = defaults.file-explorer.command;
      dispatcher-type = "exec";
    }
    {
      description = "Open Terminal";
      mod1 = mod;
      key = "T";
      command = defaults.terminal.command;
      dispatcher-type = "exec";
    }
    {
      description = "Open Browser";
      mod1 = mod;
      key = "B";
      command = defaults.browser.command;
      dispatcher-type = "exec";
    }
  ];
}