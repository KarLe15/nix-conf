{inputs, pkgs, lib, ... } : {
    imports = [
        ./walker.nix
        ./home.nix
    ];
}