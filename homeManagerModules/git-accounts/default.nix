{inputs, pkgs, lib, ... } : {
    imports = [
        ./options.nix
        ./ssh-config.nix
        ./home.nix
    ];
}