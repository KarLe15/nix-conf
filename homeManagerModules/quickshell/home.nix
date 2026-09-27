{ pkgs, lib, config, customConfigs, quickshell-pkg, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.quickshell;

  ## Pull styling from the same presets the rest of the shell uses, so Quickshell
  ## renders with the machine's active fonts and theme flavor rather than hardcoded
  ## values.
  fonts = customConfigs.styleConfigs.fonts.apply { inherit pkgs; };
  theme = customConfigs.styleConfigs.themes.apply { inherit pkgs; };

  ## Monitor + workspace layout come from the same presets Hyprland/Waybar use,
  ## so the shell draws the machine's real per-monitor workspace binding.
  monitors   = customConfigs.hardwareConfigs.monitors.apply { inherit pkgs; };
  workspaces = customConfigs.styleConfigs.workspaces.apply { inherit pkgs monitors; };

  ## Default programs (file explorer, terminal, …) — the single source of truth the
  ## rest of the config uses; the quickshell preset builds its button actions from it.
  default-programs = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };

  ## Idle schedule (lock/screen-off/suspend seconds) — the avatar popover tells
  ## you when the machine sleeps, so it reads the same preset hypridle does.
  powermanagement = customConfigs.softwareConfigs.powermanagement.apply { inherit pkgs; };

  ## Submap presentation (name/icon/color). The submaps themselves are defined in
  ## the shortcuts preset by entries naming them; this is only how the bar shows
  ## them, kept there so there is one source of truth.
  submaps = customConfigs.softwareConfigs.shortcuts.submaps or { };
  submapEntries = lib.concatStringsSep ", " (lib.mapAttrsToList (n: s:
    ''"${n}": { "name": "${s.name}", "icon": "\u${s.icon}", "color": "${s.color}" }''
  ) submaps);

  ## Quickshell-specific config (per-screen bar layout + assets) also comes from a
  ## preset in configurations/ — the module never reaches up into configurations/.
  quickshellStyle = customConfigs.styleConfigs.quickshell.apply { inherit pkgs default-programs; };

  ## Volume/Bluetooth popover knobs — the middle-click targets on the output card
  ## and the Bluetooth title, which the preset takes from the default programs.
  volumeQml = ''({ "audioManager": "${quickshellStyle.volume.audioManager}", ''
            + ''"bluetoothManager": "${quickshellStyle.volume.bluetoothManager}" })'';

  ## System panel knobs — the middle-click target on the systemd status row, which
  ## the preset takes from the default programs (already terminal-wrapped).
  systemQml = ''({ "systemdManager": "${quickshellStyle.system.systemdManager}" })'';

  ## Multimedia OSD config (see configurations/style/quickshell/presets/*.nix).
  ## Icons are hex Nerd Font codepoints in the preset and emitted as \uXXXX, the
  ## same convention the bar layout uses.
  osd = quickshellStyle.osd;
  osdIcons = lib.concatStringsSep ", " (lib.mapAttrsToList (n: v:
    ''"${n}": "\u${v}"''
  ) osd.icons);
  osdQml = ''({ "monitor": "${osd.monitor}", "variant": "${osd.variant}", ''
         + ''"accent": "${osd.accent}", "holdMs": ${toString osd.holdMs}, ''
         + ''"fadeMs": ${toString osd.fadeMs}, "placement": "${osd.placement}", ''
         + ''"margin": ${toString osd.margin}, "cardWidth": ${toString osd.cardWidth}, ''
         + ''"lowThreshold": ${toString osd.lowThreshold}, ''
         + ''"showDevice": ${lib.boolToString osd.showDevice}, ''
         + ''"icons": ({ ${osdIcons} }) })'';

  ## Command palette config (see the quickshell style preset). Named paletteCfg
  ## rather than palette to keep it clearly distinct from the Catppuccin colour
  ## palette, which now lives in qml/palette.nix.
  paletteCfg = quickshellStyle.palette;
  paletteQml = ''({ "monitor": "${paletteCfg.monitor}", "accent": "${paletteCfg.accent}", ''
             + ''"selectionStyle": "${paletteCfg.selectionStyle}", ''
             + ''"quickKeys": ${lib.boolToString paletteCfg.quickKeys}, ''
             + ''"width": ${toString paletteCfg.width}, "position": "${paletteCfg.position}", ''
             + ''"topMargin": ${toString paletteCfg.topMargin}, ''
             + ''"scrim": ${toString paletteCfg.scrim}, "maxRows": ${toString paletteCfg.maxRows}, ''
             + ''"fixedHeight": ${lib.boolToString paletteCfg.fixedHeight} })'';


  ## Avatar control centre (see the quickshell style preset). Presence colours are
  ## Theme palette *names*, resolved in QML so a theme flavor change follows. The
  ## idle subtitle needs the real hypridle schedule, which lives in the
  ## powermanagement preset — the same numbers the hypridle module renders.
  avatarCfg = quickshellStyle.avatar;
  avatarIcons = lib.concatStringsSep ", " (lib.mapAttrsToList (n: v:
    ''"${n}": "\u${v}"''
  ) avatarCfg.icons);
  avatarPresence = lib.concatStringsSep ", " (lib.mapAttrsToList (n: v:
    ''"${n}": "${v}"''
  ) avatarCfg.presence);
  avatarMirrors = lib.concatStringsSep ", " (lib.mapAttrsToList (n: v:
    ''"${n}": ${lib.boolToString v}''
  ) avatarCfg.mirrors);
  avatarFacts = lib.concatMapStringsSep ", " (f: ''"${f}"'') avatarCfg.facts;
  avatarDurations = lib.concatMapStringsSep ", " toString avatarCfg.idleDurations;
  avatarQml = ''({ "width": ${toString avatarCfg.width}, ''
            + ''"discSize": ${toString avatarCfg.discSize}, ''
            + ''"ringWidth": ${toString avatarCfg.ringWidth}, ''
            + ''"ringGap": ${toString avatarCfg.ringGap}, ''
            + ''"panelRingWidth": ${toString avatarCfg.panelRingWidth}, ''
            + ''"userName": "${avatarCfg.userName}", ''
            + ''"presence": ({ ${avatarPresence} }), ''
            + ''"idleDurations": [ ${avatarDurations} ], ''
            + ''"idleDefault": ${toString avatarCfg.idleDefault}, ''
            + ''"idleAfter": ${toString powermanagement.idleTimeouts.lockAfter}, ''
            + ''"netListHeight": ${toString avatarCfg.netListHeight}, ''
            + ''"facts": [ ${avatarFacts} ], ''
            + ''"mirrors": ({ ${avatarMirrors} }), ''
            + ''"icons": ({ ${avatarIcons} }) })'';

  ## Theme singleton, rendered by the generator the notification server also uses, so
  ## a toast can never disagree with the bar it appears under. Palette lives one level
  ## further out again, in qml/palette.nix, shared with the lock and the greeter.
  shellTheme = import ../../qml/shell/generate.nix { inherit lib theme fonts; };
  themeQml   = shellTheme.themeQml;

  ## Per-monitor workspace layout, projected from the workspaces preset into a QML
  ## data singleton. The Screen Bars pills read { id, icon, monitor } from here (the
  ## repo's Nerd Font glyphs + monitor binding); live focus/occupancy comes from
  ## Hyprland at runtime. Regenerated on rebuild — do not edit in ~/.config.
  wsEntries = lib.concatMapStringsSep ",\n" (w:
    "            { \"id\": ${toString w.id}, \"icon\": \"${w.icon}\", \"monitor\": \"${w.monitor}\" }"
  ) workspaces.workspaces_defined;

  ## Monitor-name → role map (from the disposition) so each Bar can select its
  ## modules by role. The content routing lives in Bar.qml; this is just the data.
  roleEntries = ''"${monitors.disposition.code}": "code", "${monitors.disposition.terminal}": "terminal", "${monitors.disposition.browser}": "browser"'';

  ## Per-screen bar layout (Screen Bars · Filled) — data-driven composition keyed by
  ## monitor role, provided by the quickshell style preset in configurations/ (see
  ## configurations/style/quickshell/presets/*.nix for the entry schema). A host can
  ## still override the whole map via softwareConfigs.modules.quickshell.bars.
  barsLayout = if (cfg ? bars && cfg.bars != {}) then cfg.bars else quickshellStyle.bars;

  ## Render the layout attrset into a QML object literal. `\u<hex>` is emitted for
  ## the glyph so QML interprets the escape at runtime — the backslash survives
  ## because Config.qml is generated inside a '' string (no C-escape processing).
  escStr = lib.escape [ "\"" "\\" ];
  renderEntry = e:
    let
      parts =
        [ ''"w": "${e.w}"'' ]
        ++ lib.optional (e ? icon)    ''"icon": "\u${e.icon}"''
        ++ lib.optional (e ? label)   ''"label": "${escStr e.label}"''
        ++ lib.optional (e ? color)   ''"color": "${e.color}"''
        ++ lib.optional (e ? command) ''"command": "${escStr e.command}"''
        ++ lib.optional (e ? compact) ''"compact": ${lib.boolToString e.compact}''
        ++ lib.optional (e ? dashed)  ''"dashed": ${lib.boolToString e.dashed}'';
    in "{ ${lib.concatStringsSep ", " parts} }";
  renderZone = z: "[ ${lib.concatMapStringsSep ", " renderEntry z} ]";
  renderRole = name: r:
    ''"${name}": { "left": ${renderZone r.left}, "center": ${renderZone r.center}, "right": ${renderZone r.right} }'';
  barLayoutQml =
    "({ ${lib.concatStringsSep ", " (lib.mapAttrsToList renderRole barsLayout)} })";

  configQml = ''
    pragma Singleton
    import Quickshell
    import QtQuick

    // GENERATED by homeManagerModules/quickshell/home.nix from the workspaces +
    // monitors presets. Do not edit by hand.
    Singleton {
        // Per-monitor workspace layout: id · Nerd Font glyph · target monitor.
        readonly property var workspaces: [
    ${wsEntries}
        ]

        // Monitor connector name → role ("code" | "terminal" | "browser"), so each
        // Bar can compose modules for its screen. (Parenthesised so QML reads it as
        // an object literal, not a statement block.)
        readonly property var roles: ({ ${roleEntries} })

        // The ultrawide "hub" monitor — carries global modules in later stages.
        readonly property string hubMonitor: "${monitors.disposition.browser}"

        // Workspace-session banding: absolute id = (session - 1) * band + slot.
        // The bar derives both from the ids Hyprland already reports, so sessions
        // need no extra channel. See docs/HYPRLAND_SESSIONS.md.
        readonly property int sessionBand: ${toString workspaces.sessions.band}
        readonly property int sessionCount: ${toString workspaces.sessions.count}

        // Submap presentation, keyed by submap name ("default" = no submap).
        readonly property var submaps: ({ ${submapEntries} })

        // Multimedia OSD: target monitor role, variant, accent, timing, glyphs.
        readonly property var osd: ${osdQml}

        // Volume / Bluetooth popover: the managers a middle-click opens on the
        // output card and the Bluetooth title (the controls Waybar's wireplumber
        // and bluetooth modules carried).
        readonly property var volume: ${volumeQml}

        // System panel: the systemd manager a middle-click on the status row opens.
        readonly property var system: ${systemQml}

        // Command palette: presentation + behaviour knobs.
        readonly property var palette: ${paletteQml}

        // Avatar control centre: ring + popover geometry, presence colour
        // names, idle chips, facts rows, mirror pills and glyphs.
        readonly property var avatar: ${avatarQml}

        // Per-screen bar composition, keyed by role. Each zone lists widget entries
        // dispatched by qml/widgets/WidgetSlot.qml. Generated from the barsLayout
        // preset in home.nix. (Parenthesised so QML reads it as an object literal.)
        readonly property var barLayout: ${barLayoutQml}

        // Profile photo for the avatar widget (installed alongside the QML tree).
        readonly property string profileImage: "file://${config.xdg.configHome}/quickshell/assets/profile.jpg"
    }
  '';
in
{
  config = lib.mkIf cfg.enable {
    ## Install the Quickshell binary (upstream flake build, passed in via
    ## extraSpecialArgs as quickshell-pkg). Also available as `qs` for a manual
    ## run alongside the service.
    home.packages = [ quickshell-pkg ];

    ## Quickshell as a managed user service, replacing Waybar.
    ##
    ## X-Restart-Triggers is the important part. Quickshell watches the RESOLVED
    ## path of its config files, and Home Manager installs those as symlinks into
    ## the Nix store — whose targets are immutable. So a rebuild swaps the symlink,
    ## the resolved store path never changes, the file watcher never fires, and the
    ## running shell keeps executing the previous generation until it is restarted
    ## by hand. Listing the generated content and the QML tree here makes the unit
    ## text change whenever any of them does, so home-manager's sd-switch restarts
    ## the service on activation.
    ##
    ## Reload is not an option: there is no IPC to re-read the config in place.
    systemd.user.services.quickshell = {
      Unit = {
        Description = "Quickshell desktop shell";
        Documentation = "https://quickshell.org";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ## Do not start outside a Wayland session (same guard Waybar uses).
        ConditionEnvironment = "WAYLAND_DISPLAY";
        X-Restart-Triggers = [
          "${pkgs.writeText "quickshell-generated" (themeQml + configQml)}"
          "${./qml}"
          "${quickshellStyle.profile-image}"
        ];
      };
      Service = {
        ExecStart = "${quickshell-pkg}/bin/quickshell";
        Restart = "on-failure";
        KillMode = "mixed";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile = {
      "quickshell/Theme.qml".text     = themeQml;
      "quickshell/Config.qml".text    = configQml;
      "quickshell/Popovers.qml".source = ./qml/Popovers.qml;
      "quickshell/Launcher.qml".source = ./qml/Launcher.qml;
      "quickshell/Sys.qml".source     = ./qml/Sys.qml;
      "quickshell/Presence.qml".source = ./qml/Presence.qml;
      "quickshell/Idle.qml".source    = ./qml/Idle.qml;
      "quickshell/shell.qml".source   = ./qml/shell.qml;
      "quickshell/Bar.qml".source   = ./qml/Bar.qml;
      "quickshell/Osd.qml".source   = ./qml/Osd.qml;
      "quickshell/CommandPalette.qml".source = ./qml/CommandPalette.qml;
      "quickshell/widgets".source   = ./qml/widgets;
      "quickshell/scripts".source   = ./scripts;
      "quickshell/assets/profile.jpg".source = quickshellStyle.profile-image;
    };
  };
}
