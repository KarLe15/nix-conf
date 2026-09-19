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
            osd           :: attrs;   # multimedia OSD placement, timing and glyphs
            palette       :: attrs;   # command palette presentation and behaviour
            avatar        :: attrs;   # avatar ring + control-centre popover
          }
          autostart :: [ str ]

        The `bars` attrset is serialized into Config.qml by
        homeManagerModules/quickshell/home.nix and dispatched at runtime by
        qml/widgets/WidgetSlot.qml. See the header comment in ./presets/screen-bars.nix
        for the entry schema ({ w; icon; label; color; command; compact; dashed; }).
      '';
    };
  };
}
