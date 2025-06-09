{ lib, ... }: 
let 
  softwareConfigsGenerator = {cfg, ... }: 
    let
      sw = cfg.software;
    in {
      defaults = import ./configurations/software/defaults/presets/${sw.defaults.active}.nix;
      developpement = import ./configurations/software/developpement/presets/${sw.developpement.active}.nix;
      shortcuts = import ./configurations/software/shortcuts/presets/${sw.shortcuts.active}.nix;
      launchers = import ./configurations/software/launchers/presets/${sw.launchers.active}.nix;
      powermanagement = import ./configurations/software/powermanagement/presets/${sw.powermanagement.active}.nix;
      multimedia = import ./configurations/software/multimedia/presets/${sw.multimedia.active}.nix;
      git-accounts = import ./configurations/software/git-accounts/presets/${sw.git-accounts.active}.nix;
      modules = {
        eww.enable = false;
        walker.enable = true;
        git-accounts.enable = true;
        waybar.enable = true;
      };
  };

  styleConfigsGenerator = { cfg, ... } : 
    let
      style = cfg.style;
    in {
      workspaces = import ./configurations/style/workspaces/presets/${style.workspaces.active}.nix;
      status-bars = import ./configurations/style/status-bars/presets/${style.statusbar.active}.nix;
      themes = import ./configurations/style/themes/presets/${style.themes.active}.nix;
      cursors = import ./configurations/style/cursors/presets/${style.cursors.active}.nix;
      fonts = import ./configurations/style/fonts/presets/${style.fonts.active}.nix;
      wallpaper = import ./configurations/style/wallpapers/presets/${style.wallpaper.active}.nix;
    }
  ;

  hardwareConfigsGenerator = { cfg, ... }: 
    let
      hw = cfg.hardware;
    in {
      monitors = import ./configurations/hardware/monitors/presets/${hw.monitors.active}.nix;
    }
  ;
in {
  buildCustomConfig = {cfg, ...}: {
    hardwareConfigs = hardwareConfigsGenerator { inherit cfg; };
    styleConfigs = styleConfigsGenerator { inherit cfg; };
    softwareConfigs = softwareConfigsGenerator { inherit cfg; };
  };
}