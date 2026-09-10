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
  ## `workspace_rule`, `on`, ...) — not a hyprlang section name.
  ## See docs/HYPRLAND-LUA-MIGRATION.md.

  ## Render a Lua string literal (handles quoting/escaping).
  luaStr = s: lib.generators.toLua { } s;

  ## Modifiers are a list in the preset; the Lua bind API takes "ALT+SHIFT+F".
  keyCombo = mods: key:
    lib.concatStringsSep "+" (mods ++ [ key ]);

  ## The workspaces preset is shared with waybar/quickshell and still spells its
  ## modifiers the hyprlang way ("ALT_SHIFT"), so it is normalised here rather
  ## than reshaped there.
  splitMods = m: if m == "" then [ ] else lib.splitString "_" m;

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

  ## Translate a shortcut preset entry's dispatcher into its Lua equivalent,
  ## reading named fields from `args` rather than reinterpreting one string.
  ## All `exec` shortcuts keep the uwsm wrapping for systemd session tracking.
  mkDispatcher = s:
    let
      a = s.args;
      need = field:
        a.${field} or (throw "hyprland: shortcut '${s.description}' (${s.dispatcher}) is missing args.${field}");
      cmd = if s.env != ""
            then "${s.env} uwsm app -- ${need "cmd"}"
            else "uwsm app -- ${need "cmd"}";
    in {
      exec                   = "hl.dsp.exec_cmd(${luaStr cmd})";
      killactive             = "hl.dsp.window.close()";
      forcekillactive        = "hl.dsp.window.kill()";
      togglefloating         = ''hl.dsp.window.float({ action = "toggle" })'';
      ## mode is "fullscreen" (no bar) or "maximized" (keeps the bar).
      fullscreen             = ''hl.dsp.window.fullscreen({ mode = ${luaStr (need "mode")}, action = "toggle" })'';
      togglespecialworkspace = "hl.dsp.workspace.toggle_special()";
      ## follow = false is Hyprland's "silent" move: the window goes, focus stays.
      movetoworkspace        = ''hl.dsp.window.move({ workspace = ${luaStr (need "workspace")}, follow = ${lib.boolToString (a.follow or true)} })'';
      ## Enter a submap; "default" leaves whatever submap is active.
      submap-enter           = "hl.dsp.submap(${luaStr (need "submap")})";
      resize                 = ''hl.dsp.window.resize({ x = ${toString (need "x")}, y = ${toString (need "y")} })'';
    }.${s.dispatcher}
      or (throw "hyprland: no Lua dispatcher mapping for '${s.dispatcher}' (shortcut: ${s.description})");

  ## One preset entry -> one hl.bind(). `flags` (locked / repeating / release /
  ## long_press / mouse) ride alongside the description in the options table.
  mkShortcutBind = s:
    mkBind (keyCombo s.mods s.key) (mkDispatcher s) ({ description = s.description; } // s.flags);

  ## Entries name the submap they belong to; null means always active. Submap
  ## members are held back here and rendered by the `submaps` option (Phase 4).
  globalShortcuts = builtins.filter (s: s.submap == null) shortcuts-impl;
  submapShortcuts = builtins.filter (s: s.submap != null) shortcuts-impl;
  submapNames = lib.unique (map (s: s.submap) submapShortcuts);

  ## Shortcuts from the shortcuts preset.
  shortcutBinds = map mkShortcutBind globalShortcuts;

  ## Per-workspace focus + silent move, for every key bound to that workspace.
  workspaceBinds = lib.flatten (map (ws:
    map (key: [
      (mkBind (keyCombo (splitMods ws.mod) key)
        ''hl.dsp.focus({ workspace = "${toString ws.id}" })''
        { description = "Focus workspace ${toString ws.id}"; })
      (mkBind (keyCombo (splitMods ws.mod-shift) key)
        ''hl.dsp.window.move({ workspace = "${toString ws.id}", follow = false })''
        { description = "Move window to workspace ${toString ws.id}"; })
    ]) ws.shortcut
  ) workspaces.workspaces_defined);

  ## Directional focus / window movement.
  navigationBinds = lib.flatten (map (nav:
    map (key: [
      (mkBind (keyCombo (splitMods nav.mod) key)
        ''hl.dsp.focus({ direction = "${mapDirectionToLua nav.direction}" })''
        { description = "Focus ${lib.toLower nav.direction}"; })
      (mkBind (keyCombo (splitMods nav.mod-shift) key)
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

    ## Submaps declared by the shortcuts preset (`submap = "<name>"` on an entry).
    ## Home Manager renders each as hl.define_submap("<name>", function() … end).
    ## Empty until Phase 4 populates the preset.
    submaps = lib.listToAttrs (map (name: {
      inherit name;
      value.settings.bind =
        map mkShortcutBind (builtins.filter (s: s.submap == name) submapShortcuts);
    }) submapNames);
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
