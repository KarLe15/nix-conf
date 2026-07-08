{ lib, config, ... } : {
  imports = [
  ];

  options.hardware.monitors = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "mastodant-3-screens"
      ];
      default = "mastodant-3-screens";
      description = ''
        Active monitor layout preset name.

        The selected preset must export:
          apply :: { pkgs } -> {
            definition :: [ MonitorDef ];
            disposition :: {
              code     :: str;   # monitor name for code workspaces
              terminal :: str;   # monitor name for terminal workspaces
              browser  :: str;   # monitor name for browser workspaces
            };
          }

        MonitorDef :: {
          name        :: str;    # kernel device name, e.g. "HDMI-A-2"
          width       :: int;
          height      :: int;
          refreshRate :: int;
          position    :: { x :: int; y :: int; }
          scale       :: float;
          primary     :: bool;   # optional
        }
      '';
    };
  };
}