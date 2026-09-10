{ lib }:
{
  hyprlandOutputType = lib.types.submodule {
    options = {
      sections = lib.mkOption {
        type        = lib.types.attrsOf lib.types.anything;
        default     = { };
        description = ''
          Hyprland config sections (general, input, misc, cursor, …), merged into
          the single hl.config({ … }) call. This is a fragment, not a replacement:
          stylix merges its palette into the same key, so anything set here is
          combined with it rather than overriding it.
        '';
      };
      window-rules = lib.mkOption {
        type        = lib.types.listOf lib.types.anything;
        default     = [ ];
        description = ''
          Window rules, one attrset per hl.window_rule() call. Each takes a `name`,
          a `match` table ({ class, title, … }) and the effects to apply.
        '';
      };
      workspace-rules = lib.mkOption {
        type        = lib.types.listOf lib.types.anything;
        default     = [ ];
        description = ''
          Extra workspace rules, one attrset per hl.workspace_rule() call. The
          per-workspace monitor bindings are generated from the workspaces preset;
          this is for rules that preset does not express (e.g. special workspaces).
        '';
      };
    };
  };
}
