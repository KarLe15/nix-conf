{inputs, pkgs, lib, ... } : {
    imports = [
        ./home.nix
        ./theme.nix
        ./plugin.nix
        ./ide.nix
    ];
}