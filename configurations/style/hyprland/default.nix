{ lib, ... }: {
  imports = [
  ];
  options.style.hyprland = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "mastodant-1"
      ];
      default = "mastodant-1";
      description = ''
        Active Hyprland host-configuration preset name.

        The selected preset must export:
          apply :: { pkgs, ... } -> {
            sections        :: attrs;    # config sections merged into hl.config()
            window-rules    :: [ attrs ]; # one hl.window_rule() call each
            workspace-rules :: [ attrs ]; # one hl.workspace_rule() call each
          }
          autostart :: [ str ]

        Monitors, workspaces and keybindings are NOT here — they come from the
        monitors / workspaces / shortcuts presets, which are shared with waybar and
        quickshell. This preset owns only what is specific to Hyprland itself.

        Field names are Hyprland's Lua API names, serialized as-is by
        homeManagerModules/hyprland/home.nix. The API silently ignores unrecognised
        fields, so verify new ones against src/config/lua/bindings/ in the Hyprland
        source — see docs/HYPRLAND-LUA-MIGRATION.md.
      '';
    };
  };
}
