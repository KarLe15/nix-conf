{ pkgs, lib, config, customConfigs, quickshell-pkg, ... }:

let
  cfg = customConfigs.softwareConfigs.modules.quickshell-notify;

  configDir = "$HOME/.config/quickshell-notify";

  fonts = customConfigs.styleConfigs.fonts.apply { inherit pkgs; };
  theme = customConfigs.styleConfigs.themes.apply { inherit pkgs; };

  ## The same Theme the bar renders, from the same generator — a toast must not be a
  ## different shade of mantle than the bar it appears under. Config.qml is
  ## deliberately not shared: the bar's carries its per-screen layout, and this
  ## instance will carry the notification preset (docs/NOTIFICATIONS.md D1).
  shellTheme = import ../../qml/shell/generate.nix { inherit lib theme fonts; };

  ## xdg.configFile cannot mix a source directory with a generated file, so the tree
  ## is merged in the store first — the same shape quickshell-lock uses.
  notifyTree = pkgs.runCommand "quickshell-notify-qml" { } ''
    mkdir -p $out
    cp -r ${./qml}/. $out/
    chmod -R u+w $out   # store copies come in read-only, incl. the directories

    cp ${pkgs.writeText "Theme.qml" shellTheme.themeQml} $out/Theme.qml
  '';

  ## Phase 1 runs on a throwaway session bus, where org.freedesktop.Notifications is
  ## unowned while WAYLAND_DISPLAY still reaches the real monitors — so the server
  ## under development never contends with the swaync that is serving real
  ## notifications (docs/NOTIFICATIONS.md D3). Scaffolding: both wrappers are deleted
  ## at the phase 7 flag day, along with the -dev paths they imply.
  devWrapper = pkgs.writeShellScriptBin "quickshell-notify-dev" ''
    exec ${pkgs.dbus}/bin/dbus-run-session -- \
      ${quickshell-pkg}/bin/quickshell -p "${configDir}"
  '';

  ## Sends a notification to the running dev instance instead of to whatever owns the
  ## real bus (swaync, today). The instance's private bus address is only discoverable
  ## from its own environment, so this reads it back out of /proc and forwards every
  ## argument to notify-send unchanged.
  ##
  ## `-x` (match the WHOLE command line, not a substring) is load-bearing. A plain
  ## `pgrep -f` also matches the `dbus-run-session` parent, which carries this command
  ## as its *arguments*, and any shell whose command line merely mentions the path —
  ## both of which sit on the real bus. Sending there hits swaync and looks like it
  ## worked. The bus check below is the backstop for whatever this still gets wrong.
  sendWrapper = pkgs.writeShellScriptBin "quickshell-notify-send" ''
    set -eu

    pid=$(${pkgs.procps}/bin/pgrep -f -x \
            "${quickshell-pkg}/bin/quickshell -p ${configDir}" | head -1 || true)

    if [ -z "''${pid:-}" ]; then
      echo "quickshell-notify-send: no dev instance running." >&2
      echo "  start one first:  quickshell-notify-dev" >&2
      exit 1
    fi

    bus=$(tr '\0' '\n' < "/proc/$pid/environ" \
            | grep '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2- || true)

    if [ -z "''${bus:-}" ]; then
      echo "quickshell-notify-send: pid $pid has no DBUS_SESSION_BUS_ADDRESS." >&2
      echo "  it was not started through quickshell-notify-dev." >&2
      exit 1
    fi

    if [ "$bus" = "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
      echo "quickshell-notify-send: refusing to send — the instance is on the REAL" >&2
      echo "  session bus, not a private one. That is swaync's bus." >&2
      exit 1
    fi

    exec env DBUS_SESSION_BUS_ADDRESS="$bus" ${pkgs.libnotify}/bin/notify-send "$@"
  '';
in
{
  config = lib.mkIf cfg.enable {
    ## libnotify also lands on PATH so `notify-send` is available directly — it goes
    ## to the real bus, which is useful for checking swaync still works. Scoped to
    ## this module rather than the global package list: it exists for this work and
    ## leaves with it.
    home.packages = [ devWrapper sendWrapper pkgs.libnotify ];

    xdg.configFile."quickshell-notify".source = notifyTree;

    ## No systemd.user.services block, on purpose. Enabling this module installs an
    ## inert config directory and three commands; nothing starts at login and nothing
    ## claims a bus name. The unit lands at phase 7, in the same rebuild that
    ## disables swaync — see docs/NOTIFICATIONS.md, Roadmap.
  };
}
