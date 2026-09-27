{
  apply = { pkgs, ... }@inputs:
  let
    ## The terminal every TUI entry below is wrapped in, so swapping terminals is a
    ## single edit. `-e` is the run-this-command flag ghostty shares with kitty,
    ## alacritty and foot; a terminal that spells it differently needs this changed.
    terminalCommand = "ghostty";
    inTerminal = cmd: "${terminalCommand} -e ${cmd}";
  in {
    browser = {
      command = "firefox";
      name = "Firefox";
      package = pkgs.firefox-unwrapped;
    };
    terminal = {
      command = terminalCommand;
      name = "Ghostty";
      package = pkgs.ghostty;
    };
    terminal-editor = {
      command = "nvim";
      name = "NeoVim";
      package = pkgs.neovim;
    };
    file-explorer = {
      command = "nautilus";
      name = "Nautilus";
      package = pkgs.nautilus;
    };
    email = {
      command = "thunderbird";
      name = "ThunderBird";
      package = pkgs.thunderbird-latest-unwrapped;
    };
    notification-center = {
      command = "swaync-client -t";
      name = "Open notification Center";
      package = pkgs.swaynotificationcenter;
    };
    logout = {
      command = "wleave -kf";
      name = "WLeave";
      package = pkgs.wleave;
      # FIXME :: 05/05/2025 :: Add this to fix Wlogout / Wleave issue with icons
      env = "GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };
    ## The Stargate lock (homeManagerModules/quickshell-lock): a resident quickshell
    ## instance holding an ext-session-lock client. `stargate-lock` only pokes it
    ## over IPC, so the gate is on screen in one frame.
    ##
    ## hypridle's lock_cmd, wleave and wlogout all read this one field. To fall back
    ## to hyprlock — which stays installed for exactly that reason — swap the two
    ## blocks below and rebuild.
    lockscreen = {
      command = "stargate-lock";
      name    = "Stargate Lock";
      ## Documentation only; nothing reads this field. The wrapper actually on PATH
      ## is built by the lock module against the flake's quickshell input.
      package = pkgs.quickshell;
    };
    # lockscreen = {
    #   command = "pidof hyprlock || hyprlock";  # hyprlock stays running, so it guards itself
    #   name    = "Hyprlock";
    #   package = pkgs.hyprlock;
    # };
    idlemanager = {
      command = "hypridle";
      name = "HyprIdle";
      package = pkgs.hypridle;
    };
    audiomanager = {
      command = "easyeffects";
      name = "EasyEeffects";
      package = pkgs.easyeffects;
    };
    bluetoothmanager = {
      command = "overskride";
      name = "Overskride";
      package = pkgs.overskride;
    };
    systemdmanager = {
      command = inTerminal "systemd-manager-tui";
      name = "systemd Manager TUI";
      package = pkgs.systemd-manager-tui;
    };
  };

  autostart = [
  ];
}