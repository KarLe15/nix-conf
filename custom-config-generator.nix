{ lib, ... }:
let
  types = import ./configurations/types.nix { inherit lib; };

  ## ===========================================================================
  ## Phase 3 (Option B) — Submodule-type validation helper
  ##
  ## Wraps a preset's `apply` function so that its return value is evaluated
  ## through `lib.evalModules` against the declared submodule type.  Any
  ## missing required field or wrong-typed value will be reported as a clear
  ## NixOS module evaluation error at build time rather than a cryptic
  ## missing-attribute trace inside a Home Manager module.
  ##
  ## Usage:
  ##   wrapPreset types.defaultsOutputType rawPreset
  ##
  ## The returned attrset has the same shape as the raw preset
  ## ({ apply, autostart }) but `apply` now returns a type-validated value.
  ## ===========================================================================
  wrapPreset = outputType: preset: preset // {
    apply = args:
      let
        result = preset.apply args;
        validated = (lib.evalModules {
          modules = [
            { options._v = lib.mkOption { type = outputType; }; }
            { config._v  = result; }
          ];
        }).config._v;
      in
      validated;
  };

  ## Presets that expose a function directly instead of apply/autostart
  ## (e.g. shortcuts) are left unwrapped — their output is a list of
  ## attrsets whose shape is validated informally via the option description.

  softwareConfigsGenerator = { cfg, ... }:
    let
      sw = cfg.software;
    in {
      defaults = wrapPreset types.defaultsOutputType
        (import ./configurations/software/defaults/presets/${sw.defaults.active}.nix);

      developpement = wrapPreset types.developpementOutputType
        (import ./configurations/software/developpement/presets/${sw.developpement.active}.nix);

      ## shortcuts exposes `shortcuts-definition` (a function), not `apply` —
      ## imported as-is; shape is documented in the option description.
      shortcuts =
        import ./configurations/software/shortcuts/presets/${sw.shortcuts.active}.nix;

      launchers = wrapPreset types.launchersOutputType
        (import ./configurations/software/launchers/presets/${sw.launchers.active}.nix);

      powermanagement = wrapPreset types.powermanagementOutputType
        (import ./configurations/software/powermanagement/presets/${sw.powermanagement.active}.nix);

      multimedia = wrapPreset types.multimediaOutputType
        (import ./configurations/software/multimedia/presets/${sw.multimedia.active}.nix);

      git-accounts = wrapPreset types.gitAccountsOutputType
        (import ./configurations/software/git-accounts/presets/${sw.git-accounts.active}.nix);

      shell = wrapPreset types.shellOutputType
        (import ./configurations/software/shell/presets/${sw.shell.active}.nix);

      wayland-desktop = wrapPreset types.waylandDesktopOutputType
        (import ./configurations/software/wayland-desktop/presets/${sw.wayland-desktop.active}.nix);

      ## Feature flags — now read from host NixOS options (software.modules.*)
      ## rather than being hardcoded here.
      modules = {
        inherit (sw.modules)
          waybar
          git-accounts
          ghostty
          catppuccin
          hypridle
          wleave
          zed
          rofi
          swaync
          avizo
          brave
          zen-browser
          hyprlock
          hyprpolkitagent
          zellij
          wlogout
          jetbrains
          starship
          fish
          hyprland
          wayland-desktop
          quickshell;
      };
    };

  styleConfigsGenerator = { cfg, ... }:
    let
      style = cfg.style;
    in {
      workspaces =
        import ./configurations/style/workspaces/presets/${style.workspaces.active}.nix;

      status-bars =
        import ./configurations/style/status-bars/presets/${style.statusbar.active}.nix;

      themes = wrapPreset types.themesOutputType
        (import ./configurations/style/themes/presets/${style.themes.active}.nix);

      cursors = wrapPreset types.cursorsOutputType
        (import ./configurations/style/cursors/presets/${style.cursors.active}.nix);

      fonts = wrapPreset types.fontsOutputType
        (import ./configurations/style/fonts/presets/${style.fonts.active}.nix);

      wallpaper = wrapPreset types.wallpaperOutputType
        (import ./configurations/style/wallpapers/presets/${style.wallpaper.active}.nix);
    };

  hardwareConfigsGenerator = { cfg, ... }:
    let
      hw = cfg.hardware;
    in {
      monitors = wrapPreset types.monitorsOutputType
        (import ./configurations/hardware/monitors/presets/${hw.monitors.active}.nix);
    };

in {
  ## buildCustomConfig receives `cfg` as the raw attrset returned by the host's
  ## options.nix — evaluated outside the NixOS module system, before any module
  ## merge happens.  If the host selects a profile (cfg.profile.active), we
  ## import the profile preset and use it as the base, then overlay the host's
  ## own values on top so that machine-specific overrides always win.
  buildCustomConfig = { cfg, ... }:
    let
      profileDefaults =
        if cfg ? profile && cfg.profile ? active
        then import ./configurations/profiles/presets/${cfg.profile.active}.nix
        else {};

      ## Profile provides defaults; host cfg values take precedence.
      effectiveCfg = lib.recursiveUpdate profileDefaults cfg;
    in {
      hardwareConfigs = hardwareConfigsGenerator { cfg = effectiveCfg; };
      styleConfigs    = styleConfigsGenerator    { cfg = effectiveCfg; };
      softwareConfigs = softwareConfigsGenerator { cfg = effectiveCfg; };
    };
}