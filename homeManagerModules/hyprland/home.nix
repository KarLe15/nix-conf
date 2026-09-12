{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.hyprland;

  activeMonitorConfig = customConfigs.hardwareConfigs.monitors.apply { inherit pkgs; };
  workspaces = customConfigs.styleConfigs.workspaces.apply { monitors = activeMonitorConfig; inherit pkgs; };
  cursor = customConfigs.styleConfigs.cursors.apply { inherit pkgs; };
  ## Host-specific Hyprland configuration (sections, window/workspace rules).
  hyprlandStyle = customConfigs.styleConfigs.hyprland.apply { inherit pkgs; };
  defaults = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
  launchers = customConfigs.softwareConfigs.launchers.apply { inherit pkgs; };
  developpement = customConfigs.softwareConfigs.developpement.apply { inherit pkgs; };
  multimedia = customConfigs.softwareConfigs.multimedia.apply { inherit pkgs; };
  shortcuts-impl = customConfigs.softwareConfigs.shortcuts.shortcuts-definition { inherit defaults developpement launchers pkgs multimedia ; };
  autostart-services =
        customConfigs.softwareConfigs.defaults.autostart
    ++  customConfigs.softwareConfigs.launchers.autostart
    ++  customConfigs.softwareConfigs.developpement.autostart
    ++  customConfigs.styleConfigs.themes.autostart
    ++  customConfigs.styleConfigs.cursors.autostart
  ;

  ## Commands to run once the compositor is up.
  startupCommands = [
    "hyprctl setcursor ${toString cursor.default.exact-name} ${toString cursor.default.size}"
  ] ++ autostart-services;

  ## =====================< Bind data (Strategy A) >===========================
  ## Nix emits *data* only — no Lua source. qml-style split: the generated
  ## data.lua is a plain table, and the checked-in lua/*.lua turn it into hl.*
  ## calls. Nothing here knows the hl API exists, so a wrong dispatcher name is
  ## a Lua error naming the entry rather than silent nonsense in the config.
  ## See docs/HYPRLAND-LUA-MIGRATION.md.

  ## Modifiers are a list in the preset; the Lua bind API takes "ALT+SHIFT+F".
  keyCombo = mods: key:
    lib.concatStringsSep "+" (mods ++ [ key ]);

  ## The workspaces preset is shared with waybar/quickshell and still spells its
  ## modifiers the hyprlang way ("ALT_SHIFT"), so it is normalised here rather
  ## than reshaped there.
  splitMods = m: if m == "" then [ ] else lib.splitString "_" m;

  mapDirectionToLua = direction: {
    Left  = "left";
    Right = "right";
    Up    = "up";
    Down  = "down";
  }.${direction} or (throw "Unknown direction for Hyprland command: ${direction}");

  ## One shortcut preset entry -> one data record. `args` is normalised here so
  ## lua/binds.lua never has to supply a default: `follow` in particular is always
  ## emitted, because its absence is what made silent moves regress once already.
  shortcutData = s: {
    keys = keyCombo s.mods s.key;
    inherit (s) dispatcher;
    args =
      if s.dispatcher == "exec" then {
        cmd = if s.env != ""
              then "${s.env} uwsm app -- ${s.args.cmd}"
              else "uwsm app -- ${s.args.cmd}";
      }
      else if s.dispatcher == "movetoworkspace" then {
        inherit (s.args) workspace;
        follow = s.args.follow or true;
      }
      else s.args;
    opts = { description = s.description; } // s.flags;
  };

  ## Entries name the submap they belong to; null means always active.
  globalShortcuts = builtins.filter (s: s.submap == null) shortcuts-impl;
  submapShortcuts = builtins.filter (s: s.submap != null) shortcuts-impl;
  submapNames = lib.unique (map (s: s.submap) submapShortcuts);

  ## Per-workspace focus + silent move, for every key bound to that workspace.
  workspaceBindData = lib.flatten (map (ws:
    map (key: [
      {
        keys = keyCombo (splitMods ws.mod) key;
        dispatcher = "focus-slot";
        args = { slot = ws.id; };
        opts = { description = "Focus workspace ${toString ws.id}"; };
      }
      {
        keys = keyCombo (splitMods ws.mod-shift) key;
        dispatcher = "move-to-slot";
        args = { slot = ws.id; follow = false; };
        opts = { description = "Move window to workspace ${toString ws.id}"; };
      }
    ]) ws.shortcut
  ) workspaces.workspaces_defined);

  ## Directional focus / window movement.
  navigationBindData = lib.flatten (map (nav:
    map (key: [
      {
        keys = keyCombo (splitMods nav.mod) key;
        dispatcher = "focus-direction";
        args = { direction = mapDirectionToLua nav.direction; };
        opts = { description = "Focus ${lib.toLower nav.direction}"; };
      }
      {
        keys = keyCombo (splitMods nav.mod-shift) key;
        dispatcher = "move-direction";
        args = { direction = mapDirectionToLua nav.direction; };
        opts = { description = "Move window ${lib.toLower nav.direction}"; };
      }
    ]) nav.shortcut
  ) workspaces.navigation);

  ## Mouse binds carry the `mouse` option rather than a separate dispatcher list.
  mouseBindData = [
    {
      keys = "ALT+mouse:272";
      dispatcher = "window-drag";
      args = { };
      opts = { mouse = true; description = "Move window"; };
    }
    {
      keys = "ALT+mouse:273";
      dispatcher = "window-resize-mouse";
      args = { };
      opts = { mouse = true; description = "Resize window"; };
    }
  ];

  ## The generated data module. lib.generators.toLua does the serialisation, so
  ## no Lua source is ever built by string concatenation.
  hyprData = {
    binds =
         map shortcutData globalShortcuts
      ++ workspaceBindData
      ++ navigationBindData
      ++ mouseBindData;

    submaps = lib.listToAttrs (map (name: {
      inherit name;
      value = map shortcutData (builtins.filter (s: s.submap == name) submapShortcuts);
    }) submapNames);

    startup = startupCommands;

    ## Session banding — lua/sessions.lua owns the live `session` value.
    sessions = workspaces.sessions;

    ## Slot -> monitor map, so a session switch can pick a default slot per screen.
    slots = map (ws: { slot = ws.id; monitor = ws.monitor; }) workspaces.workspaces_defined;
  };

  dataLua = ''
    -- GENERATED by homeManagerModules/hyprland/home.nix from the shortcuts,
    -- workspaces and monitors presets. Do not edit by hand.
    return ${lib.generators.toLua { } hyprData}
  '';
in {
  config = lib.mkIf cfg.enable {
  stylix.targets.hyprland.enable = true;
  ## INFO :: The stylix module enables a systemD module and the uwsm is enabled with sddm and hyprland so the hyprpaper is loaded
  stylix.targets.hyprpaper.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    ## Hyprland 0.55+ dropped hyprlang in practice; Home Manager still defaults to
    ## it because home.stateVersion < 26.05, so the format is selected explicitly.
    configType = "lua";

    ## data.lua is generated and required by the others; binds/startup are
    ## checked-in Lua and auto-required by the generated hyprland.lua.
    extraLuaFiles = {
      "data"    = { content = dataLua;        autoLoad = false; };
      "sessions" = { content = ./lua/sessions.lua; autoLoad = false; };
      "binds"   = { content = ./lua/binds.lua;   };
      "startup" = { content = ./lua/startup.lua; };
    };

    settings = {

      ## hl.monitor({ output, mode, position, scale })
      monitor = map (m: {
        output   = m.name;
        mode     = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
        position = "${toString m.position.x}x${toString m.position.y}";
        scale    = m.scale;
      }) activeMonitorConfig.definition;

      ## Config sections from the host preset, merged into one hl.config() call.
      ## Stylix merges its palette into this same key (it is configType-aware),
      ## which is why this stays in `settings` rather than moving to data.lua.
      config = hyprlandStyle.sections;

      ## https://wiki.hypr.land/Configuring/Window-Rules/
      window_rule = hyprlandStyle.window-rules;

      ## https://wiki.hypr.land/Configuring/Workspace-Rules/
      ## One rule per (session, slot): `hl.dsp.window.move({ workspace = … })` takes
      ## no monitor argument, so without a rule for a banded id Hyprland picks the
      ## focused monitor and the 3x3 grid scrambles outside session 1.
      ## See docs/HYPRLAND_SESSIONS.md (Why 81 rules).
      workspace_rule =
        (lib.flatten (map (session:
          map (ws: {
            workspace = toString ((session - 1) * workspaces.sessions.band + ws.id);
            monitor = ws.monitor;
          }) workspaces.workspaces_defined
        ) (lib.range 1 workspaces.sessions.count)))
        ++ hyprlandStyle.workspace-rules;
    };
  };
  };
}
