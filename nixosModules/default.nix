{config, lib, pkgs, hardwareConfigs, styleConfigs, ... } : {
    imports = [
        ./cursors/configuration.nix
        ./stylix/configuration.nix
    ];
}
