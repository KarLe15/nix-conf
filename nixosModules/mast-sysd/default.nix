{
  config,
  lib,
  pkgs,
  mast-sysd-pkg,
  ...
}:

let
  cfg = config.software.modules.mast-sysd;

  settingsFormat = pkgs.formats.toml { };
  configFile = settingsFormat.generate "mast-sysd-config.toml" {
    socketPath = "/run/mast-sysd/mast-sysd.sock";
    group = "mast-sysd";
    metricsIntervalMs = cfg.metricsIntervalMs;
    contextIntervalMs = cfg.contextIntervalMs;
    sessionUsers = cfg.sessionUsers;
    scx.enabled = false;
    scx.allowedSchedulers = [ ];
  };
in
{
  options.software.modules.mast-sysd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the mast-sysd system daemon (metrics/context/scx source of truth).";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = mast-sysd-pkg;
      description = "The mast-sysd package, built by this flake from daemons/mast-sysd.";
    };

    metricsIntervalMs = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "Metrics sampling interval in milliseconds.";
    };

    contextIntervalMs = lib.mkOption {
      type = lib.types.int;
      default = 5000;
      description = "Context probing interval in milliseconds.";
    };

    sessionUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users whose session bus (/run/user/&lt;uid&gt;/bus) the daemon may
        connect to for session-scoped probes (GameMode today).
      '';
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users added to the mast-sysd group — full read+write access to the
        socket (Quickshell runs as this user).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.mast-sysd = { };

    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "mast-sysd" ];
    });

    environment.etc."mast-sysd/config.toml".source = configFile;

    systemd.services.mast-sysd = {
      description = "Mastodant system daemon — metrics/context/scx source of truth for the shell";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${cfg.package}/bin/mast-sysd run";
        Restart = "on-failure";
        RestartSec = 2;
        RuntimeDirectory = "mast-sysd";
        RuntimeDirectoryMode = "0755";
        # Phase 4 adds: After = [ "scx_loader.service" ]; Wants = [ "scx_loader.service" ];
      };
    };
  };
}
