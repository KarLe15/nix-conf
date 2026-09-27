{ pkgs, lib, config, customConfigs, quickshell-pkg, ... }:

let
  cfg = customConfigs.softwareConfigs.modules.quickshell-lock;

  ## Same presets the SDDM greeter reads, so the lock and the login screen are the
  ## same gate room rather than two takes on it.
  stargate = customConfigs.styleConfigs.stargate.apply { inherit pkgs; };
  theme    = customConfigs.styleConfigs.themes.apply { inherit pkgs; };
  fonts    = customConfigs.styleConfigs.fonts.apply { inherit pkgs; };

  generated = import ../../qml/stargate/generate.nix {
    inherit lib fonts theme;
    style = stargate;
  };

  ## The shared gate tree plus this module's own entry point, gate screen and the
  ## two widgets that talk to PAM and logind. Merged into one directory so the
  ## implicit same-directory imports resolve, then handed to quickshell as a config
  ## folder — hence shell.qml rather than Main.qml.
  lockTree = pkgs.runCommand "stargate-lock-qml" { } ''
    mkdir -p $out
    cp -r ${../../qml/stargate}/. $out/
    chmod -R u+w $out   # store copies come in read-only, incl. the directories
    cp -r ${./qml}/. $out/
    chmod -R u+w $out

    cp ${pkgs.writeText "Theme.qml" generated.themeQml}   $out/Config/Theme.qml
    cp ${pkgs.writeText "Config.qml" generated.configQml} $out/Config/Config.qml

    ## generate.nix is a Nix file, not QML — it must not ship inside the tree.
    rm -f $out/generate.nix
  '';

  ## What hypridle, wleave and wlogout actually run. The lock instance is already
  ## resident; this only tells it to engage, so the gate is on screen in one frame
  ## instead of cold-starting into a blank compositor.
  lockWrapper = pkgs.writeShellScriptBin "stargate-lock" ''
    exec ${quickshell-pkg}/bin/quickshell -p "$HOME/.config/quickshell-lock" ipc call lock lock
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ lockWrapper ];

    xdg.configFile."quickshell-lock".source = lockTree;

    ## A second quickshell instance, separate from the bar on purpose: a crash in
    ## bar code must not be able to take the lock down, and vice versa.
    ##
    ## Restart=always is load-bearing rather than tidy. ext-session-lock keeps the
    ## compositor blocked if the lock client dies while locked, with no way to type
    ## a password; systemd brings it straight back, and shell.qml re-locks on start
    ## when logind's LockedHint says the session is still locked.
    ##
    ## X-Restart-Triggers for the same reason as the bar's (see
    ## homeManagerModules/quickshell/home.nix): Home Manager installs the config as
    ## a symlink into the store, whose target never changes, so the file watcher
    ## never fires and only a changed unit text gets the new generation running.
    systemd.user.services.quickshell-lock = {
      Unit = {
        Description = "Stargate lock screen (quickshell session lock)";
        Documentation = "https://quickshell.org";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
        X-Restart-Triggers = [
          "${pkgs.writeText "stargate-lock-generated" (generated.themeQml + generated.configQml)}"
          "${./qml}"
          "${../../qml/stargate}"
        ];
      };
      Service = {
        ExecStart = "${quickshell-pkg}/bin/quickshell -p %h/.config/quickshell-lock";
        Restart = "always";
        RestartSec = 1;
        KillMode = "mixed";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
