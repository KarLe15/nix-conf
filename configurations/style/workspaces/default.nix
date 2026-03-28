{ lib, config, ... } : {
  imports = [
  ];
  options.style.workspaces = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "standard-3-screen"
      ];
      default = "standard-3-screen";
      description = ''
        Active workspace layout preset name.

        The selected preset must export:
          apply :: { pkgs, monitors } -> {
            workspaces_defined :: [ WorkspaceDef ];
            navigation         :: [ NavDef ];
          }
          autostart :: [ str ]

        WorkspaceDef :: {
          id        :: int;
          icon      :: str;            # Nerd Font glyph
          shortcut  :: [ str ];        # list of key names that activate this workspace
          monitor   :: str;            # target monitor device name
          mod       :: str;            # modifier key, e.g. "ALT"
          mod-shift :: str;            # modifier for move-to-workspace, e.g. "ALT_SHIFT"
        }

        NavDef :: {
          direction :: "Left" | "Right" | "Up" | "Down";
          shortcut  :: [ str ];
          mod       :: str;
          mod-shift :: str;
        }
      '';
    };
  };
}