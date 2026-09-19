{config, lib, pkgs, customConfigs, ... }@inputs : {
    imports = [
        ## mast-sysd module intentionally not imported yet — build-only phase.
        ## To activate: ./mast-sysd (+ hosts/mastodant-1/services-configuration.nix
        ## sets software.modules.mast-sysd.*). See docs/MASTODANT-SYSD.md.
    ];
}
