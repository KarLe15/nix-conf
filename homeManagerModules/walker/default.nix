{inputs, pkgs, lib, ... } : {
    imports = [
        ./walker.nix
        ./home.nix
    ];

    ## TODO :: 06/04/2024 :: Home-Manager module not merged into home-manager repo 
    ## Using Custom Home-manager module defined by KarLe
    # programs.walker = {
    #     enable = true;
    #     package = pkgs.walker;
    #     config = {
    #         app_launch_prefix = "uwsm app --";
    #     };
    # }

}