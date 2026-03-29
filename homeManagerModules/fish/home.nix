{ inputs, pkgs, lib, config, customConfigs, ... }:
let
  cfg   = customConfigs.softwareConfigs.modules.fish;
  shell = customConfigs.softwareConfigs.shell.apply { inherit pkgs; };
in {
  config = lib.mkIf cfg.enable {
    programs.direnv.enableFishIntegration = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        ${shell.defaultPrompt.initCommand.fish}
        set -U fish_greeting ""
      '';
      shellAliases = shell.aliases;
    };
  };
}
