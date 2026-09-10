{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.hyprland;
  inherit (lib.generators) mkLuaInline;

  activeMonitorConfig = customConfigs.hardwareConfigs.monitors.apply { inherit pkgs; };
  workspaces = customConfigs.styleConfigs.workspaces.apply { monitors = activeMonitorConfig; inherit pkgs; };
  cursor = customConfigs.styleConfigs.cursors.apply { inherit pkgs; };
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

  ## ==========================< Lua config helpers >==========================
  ## Hyprland 0.55+ configures itself in Lua; Home Manager renders every key of
  ## `settings` as a literal `hl.<key>(...)` call, so each key below must be a
  ## real function of the hl API (`config`, `monitor`, `bind`, `window_rule`,
  ## `workspace_rule`, `exec_once`, ...) — not a hyprlang section name.
  ## See docs/HYPRLAND-LUA-MIGRATION.md.

  ## Render a Lua string literal (handles quoting/escaping).
  luaStr = s: lib.generators.toLua { } s;

  ## hyprlang spelled modifiers "ALT_SHIFT"; the Lua bind API takes "ALT+SHIFT".
  keyCombo = mods: key:
    if mods == "" then key
    else "${lib.replaceStrings [ "_" ] [ "+" ] mods}+${key}";

  ## `hl.bind(keys, <dispatcher>, <opts>)`. The dispatcher is raw Lua, so it is
  ## wrapped in mkLuaInline; opts are omitted entirely when empty.
  mkBind = keys: dispatcher: opts:
    { _args = [ keys (mkLuaInline dispatcher) ] ++ lib.optional (opts != { }) opts; };

  mapDirectionToLua = direction: {
    Left  = "left";
    Right = "right";
    Up    = "up";
    Down  = "down";
  }.${direction} or (throw "Unknown direction for Hyprland command: ${direction}");

  ## Translate a shortcut preset entry's dispatcher into its Lua equivalent.
  ## All `exec` shortcuts keep the uwsm wrapping for systemd session tracking.
  mkDispatcher = s:
    let
      cmd = if s.env != ""
            then "${s.env} uwsm app -- ${s.command}"
            else "uwsm app -- ${s.command}";
    in {
      exec                   = "hl.dsp.exec_cmd(${luaStr cmd})";
      killactive             = "hl.dsp.window.close()";
      forcekillactive        = "hl.dsp.window.kill()";
      togglefloating         = ''hl.dsp.window.float({ action = "toggle" })'';
      ## hyprlang `fullscreen, 0` = true fullscreen, `, 1` = maximize (keeps the bar).
      fullscreen             = ''hl.dsp.window.fullscreen({ mode = ${if s.command == "0" then "\"fullscreen\"" else "\"maximized\""}, action = "toggle" })'';
      togglespecialworkspace = "hl.dsp.workspace.toggle_special()";
      movetoworkspacesilent  = "hl.dsp.window.move({ workspace = ${luaStr s.command}, silent = true })";
    }.${s.dispatcher-type}
      or (throw "hyprland: no Lua dispatcher mapping for '${s.dispatcher-type}' (shortcut: ${s.description})");

  ## Shortcuts from the shortcuts preset.
  shortcutBinds = map (s:
    mkBind (keyCombo s.mod1 s.key) (mkDispatcher s) { description = s.description; }
  ) shortcuts-impl;

  ## Per-workspace focus + silent move, for every key bound to that workspace.
  workspaceBinds = lib.flatten (map (ws:
    map (key: [
      (mkBind (keyCombo ws.mod key)
        ''hl.dsp.focus({ workspace = "${toString ws.id}" })''
        { description = "Focus workspace ${toString ws.id}"; })
      (mkBind (keyCombo ws.mod-shift key)
        ''hl.dsp.window.move({ workspace = "${toString ws.id}", silent = true })''
        { description = "Move window to workspace ${toString ws.id}"; })
    ]) ws.shortcut
  ) workspaces.workspaces_defined);

  ## Directional focus / window movement.
  navigationBinds = lib.flatten (map (nav:
    map (key: [
      (mkBind (keyCombo nav.mod key)
        ''hl.dsp.focus({ direction = "${mapDirectionToLua nav.direction}" })''
        { description = "Focus ${lib.toLower nav.direction}"; })
      (mkBind (keyCombo nav.mod-shift key)
        ''hl.dsp.window.move({ direction = "${mapDirectionToLua nav.direction}" })''
        { description = "Move window ${lib.toLower nav.direction}"; })
    ]) nav.shortcut
  ) workspaces.navigation);

  ## Mouse binds are ordinary binds carrying the `mouse` option in Lua.
  mouseBinds = [
    (mkBind "ALT+mouse:272" "hl.dsp.window.drag()"   { mouse = true; description = "Move window"; })
    (mkBind "ALT+mouse:273" "hl.dsp.window.resize()" { mouse = true; description = "Resize window"; })
  ];
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
    settings = {

      ## hl.monitor({ output, mode, position, scale })
      monitor = map (m: {
        output   = m.name;
        mode     = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
        position = "${toString m.position.x}x${toString m.position.y}";
        scale    = m.scale;
      }) activeMonitorConfig.definition;

      ## Startup Scripts. There is no hl.exec_once() in the Lua API; startup
      ## commands run from a `hyprland.start` event handler instead — the same
      ## pattern Home Manager and Stylix use internally.
      on = {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
            ${lib.concatMapStrings (c: "  hl.exec_cmd(${luaStr c})\n") startupCommands}end
          '')
        ];
      };

      ## Everything that used to be a hyprlang section now lives under hl.config().
      ## Stylix merges its palette into this same key (it is configType-aware).
      config = {
        general = {
          ## hyprlang spelled this "10,3,5,3" (top,right,bottom,left). The Lua
          ## css_gap type takes an integer or a table with those named fields.
          gaps_out = { top = 10; right = 3; bottom = 5; left = 3; };
        };

        input = {
          kb_layout = "fr";
          numlock_by_default = true;
        };
      };

      ## Shortcuts definition
      bind = shortcutBinds ++ workspaceBinds ++ navigationBinds ++ mouseBinds;

      ## https://wiki.hypr.land/Configuring/Window-Rules/
      window_rule = [
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

      ## https://wiki.hypr.land/Configuring/Workspace-Rules/
      workspace_rule =
        (map (ws: {
          workspace = toString ws.id;
          monitor = ws.monitor;
        }) workspaces.workspaces_defined)
        ++ [
          {
            workspace = "special:special";
            border_size = 40;
            gaps_out = 40;
          }
        ];
    };
  };
  };
}
