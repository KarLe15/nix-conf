{ lib, ... }: {
  imports = [
  ];
  options.style.quickshell = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "screen-bars"
      ];
      default = "screen-bars";
      description = ''
        Active Quickshell shell layout preset name.

        The selected preset must export:
          apply :: { pkgs, ... } -> {
            profile-image :: path;    # avatar photo installed into the shell
            bars          :: attrs;   # per-role bar layout, keyed by monitor role
                                      #   (code/terminal/browser/other); each role has
                                      #   left/center/right lists of widget entries.
          }
          autostart :: [ str ]

        The `bars` attrset is serialized into Config.qml by
        homeManagerModules/quickshell/home.nix. See its defaultBarsLayout comment
        for the entry schema ({ w; icon; label; color; compact; dashed; }).
      '';
    };
  };
}
