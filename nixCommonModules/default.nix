{config, lib, pkgs, customConfigs, ... } : {
    imports = [
        ./cursors/configuration.nix
        ./stylix/configuration.nix
        ./secrets/configuration.nix
    ];
}
