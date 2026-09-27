{ config, lib, pkgs, customConfigs, ... }:

let
  cfg = config.software.modules.sddm;

  ## Presentation comes from the same presets the rest of the desktop uses, so the
  ## greeter renders in the machine's active theme flavor and fonts rather than
  ## hardcoded values. Same sourcing as homeManagerModules/quickshell/home.nix.
  stargate = customConfigs.styleConfigs.stargate.apply { inherit pkgs; };
  theme    = customConfigs.styleConfigs.themes.apply { inherit pkgs; };
  fonts    = customConfigs.styleConfigs.fonts.apply { inherit pkgs; };
  monitors = customConfigs.hardwareConfigs.monitors.apply { inherit pkgs; };

  ## Theme.qml and Config.qml are rendered by the shared generator, the same one the
  ## lock screen uses, so the two screens cannot drift apart on colour or geometry.
  generated = import ../../qml/stargate/generate.nix {
    inherit lib fonts theme;
    style = stargate;
  };

  metadataDesktop = ''
    [SddmGreeterTheme]
    Name=Stargate
    Description=SGC gate room — dial in to log in
    Type=sddm-theme
    Version=1.0
    License=MIT
    Theme-Id=stargate
    Theme-API=2.0
    # Without this the daemon defaults to 5 and goes looking for a `sddm-greeter`
    # binary that a Qt6-only SDDM does not ship, then silently drops the theme
    # (src/common/ThemeMetadata.cpp:64, src/daemon/Greeter.cpp:95).
    QtVersion=6
    MainScript=Main.qml
    ConfigFile=theme.conf
  '';

  ## Only the knobs worth changing without a rebuild live here. SDDM also reads
  ## theme.conf.user, so a writable copy of the theme can be driven through every
  ## state under `sddm-greeter-qt6 --test-mode`.
  themeConf = ''
    [General]
    # auto | gate | dhd | telemetry — force a screen regardless of the connector
    previewScreen=auto
    # live | dialing | error | capslock | success — force a gate state
    previewState=live
  '';

  themePackage = pkgs.runCommand "sddm-stargate-theme"
    {
      meta = {
        description = "SDDM greeter theme: the SGC gate room across three monitors";
        platforms   = lib.platforms.linux;
      };
    }
    ''
      dir=$out/share/sddm/themes/stargate
      mkdir -p "$dir"

      ## The shared gate tree first, then the greeter's own Main.qml, GateScreen and
      ## the two widgets that read SDDM's context objects — they land in the same
      ## directories so the implicit same-directory imports keep resolving.
      cp -r ${../../qml/stargate}/. "$dir/"
      chmod -R u+w "$dir"   # store copies come in read-only, incl. the directories
      cp -r ${./theme}/. "$dir/"
      chmod -R u+w "$dir"

      cp ${pkgs.writeText "Theme.qml" generated.themeQml}     "$dir/Config/Theme.qml"
      cp ${pkgs.writeText "Config.qml" generated.configQml}   "$dir/Config/Config.qml"
      cp ${pkgs.writeText "metadata.desktop" metadataDesktop} "$dir/metadata.desktop"
      cp ${pkgs.writeText "theme.conf" themeConf}             "$dir/theme.conf"

      ## generate.nix is a Nix file, not QML — it must not ship inside the theme.
      rm -f "$dir/generate.nix"
    '';

  ## Typo guard: a connector named in the preset that the monitors preset does not
  ## know about will never match a screen. Warn rather than fail — the greeter
  ## still comes up, and a host may legitimately run with a monitor unplugged.
  knownMonitors  = map (m: m.name) monitors.definition;
  unknownScreens = lib.filter (n: !(lib.elem n knownMonitors))
    (lib.attrValues stargate.screens);
in
{
  options.software.modules.sddm = {
    enable = lib.mkOption {
      type    = lib.types.bool;
      default = false;
      description = ''
        Install and select the Stargate SDDM greeter theme. Requires
        services.displayManager.sddm.enable — this module only supplies the
        theme, it does not turn the display manager on.
      '';
    };

    package = lib.mkOption {
      type    = lib.types.package;
      default = themePackage;
      defaultText = lib.literalExpression "the theme built from qml/stargate, ./theme and the active presets";
      description = ''
        The built theme. Exposed so it can be previewed without a rebuild:

          sddm-greeter-qt6 --test-mode --theme \
            "$(nix build --no-link --print-out-paths \
               .#nixosConfigurations.<host>.config.software.modules.sddm.package)/share/sddm/themes/stargate"
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (unknownScreens != [ ]) ''
      sddm-stargate: the stargate style preset assigns screens to connectors the active
      monitors preset does not define: ${lib.concatStringsSep ", " unknownScreens}.
      Those screens will never be drawn; the gate falls back to the widest monitor.
    '';

    environment.systemPackages = [ cfg.package ];

    ## SDDM resolves Theme.Current against /run/current-system/sw/share/sddm/themes,
    ## so the theme *name* — not a store path — is what belongs here.
    services.displayManager.sddm.theme = "stargate";

    ## The greeter runs as the `sddm` user, outside the Home Manager profile, so it
    ## only sees fonts installed system-wide. Stylix already installs these from the
    ## same preset; listing them makes the greeter independent of that.
    fonts.packages = [
      fonts.mono.package
      fonts.sansSerif.package
    ];
  };
}
