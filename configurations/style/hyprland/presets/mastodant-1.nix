## Hyprland host configuration for mastodant-1. Owns what is specific to the
## compositor on this machine; monitors, workspaces and keybindings come from
## their own (shared) presets.
##
## Field names are Hyprland Lua API names and are serialized as-is. The API
## accepts and silently ignores unknown fields, so check any new one against
## src/config/lua/bindings/ in the Hyprland source before trusting it.
{
  apply = { pkgs, ... }: {

    ## Merged into the single hl.config({ … }) call, alongside stylix's palette.
    sections = {
      general = {
        ## css_gap: an integer, or named edges. hyprlang spelled this "10,3,5,3"
        ## (top,right,bottom,left).
        gaps_out = { top = 10; right = 3; bottom = 5; left = 3; };
      };

      input = {
        kb_layout = "fr";
        numlock_by_default = true;
      };
    };

    ## One hl.window_rule() per entry.
    window-rules = [
      {
        name = "satty";
        match = { class = "com.gabm.satty"; };
        float = true; center = true; no_initial_focus = true;
        decorate = true; border_size = 40;
      }
      ## Dialog to save / load file
      {
        name = "portal-gtk";
        match = { class = "Xdg-desktop-portal-gtk"; };
        center = true; rounding = 0; border_size = 0;
      }
      ## Brave Upload
      # classes :
      #   - Main Window 'brave-browser'
      #   - Popups   'brave'
      # # 1084 653  Value tested on screen
      {
        name = "brave-popup";
        match = { class = "brave"; };
        float = true; center = true; no_initial_focus = true;
        max_size = [ 1084 653 ];
      }
      ## VSCodium dialogs
      {
        name = "codium-dialog";
        match = { class = "codium"; title = "Open.*"; };
        float = true; center = true; no_initial_focus = true;
        no_anim = true;
        max_size = [ 1084 653 ];
      }
    ];

    ## Extra hl.workspace_rule() entries. The per-workspace monitor bindings are
    ## generated from the workspaces preset and are not repeated here.
    workspace-rules = [
      {
        workspace = "special:special";
        border_size = 40;
        gaps_out = 40;
      }
    ];
  };

  autostart = [
  ];
}
