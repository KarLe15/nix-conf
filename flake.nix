{
  description = "Flake definition";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-darwin.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    ragenix = {
      url = "github:yaxitech/ragenix";
    };
    
    stylix.url = "github:danth/stylix";
    ## Use Catpuccin for not available modules on stylix
    catppuccin.url = "github:catppuccin/nix";

    hyprland.url = "github:hyprwm/Hyprland";


    # walker = {
    #   url = "github:abenz1267/walker";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Base 16 utils from base16 yaml to Nix Set
    base16utils = {
      url = "github:SenchoPens/base16.nix";
    };

  };

  outputs = { 
    self, nixpkgs, nixpkgs-darwin, darwin, home-manager, 
    ragenix, stylix, catppuccin, hyprland, base16utils, 
    ... 
  }@flakeInputs :
    let 

      mkHomeManagerConfig = { user, system, customConfigs, ... }@mkHomeManagerConfigInputs: {
        ## INFO :: To use the same NixPkgs Instance from Nixos and HomeManager to ensure sync :: https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module
        home-manager.useGlobalPkgs = true;
        ## INFO :: Value set to use nixos-rebuild build-vm :: https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module
        home-manager.useUserPackages = true;
        home-manager.users.${user} = {
          ## INFO :: 05/04/2025 :: Preloaded modules for HomeManager
          ## INFO :: Example :: modules that defines utils / configurations to be available in all homeManager sub modules
          imports = [
            ./homeManagerModules
            base16utils.homeManagerModule
            catppuccin.homeModules.catppuccin
            ragenix.homeManagerModules.default
            ## TODO :: 06/04/2024 :: Home-Manager module not merged into home-manager repo 
            ## Using Custom Home-manager module defined by KarLe
            # walker.homeManagerModules.default 
          ];
        };
        home-manager.extraSpecialArgs =  {
          inherit customConfigs;
        };
      };

      mkCommonOsConfig = { system, customConfigs, ragenix, ragenixKeyPath, ... }@mkCommonOsConfigInput: {
        imports = [ ./nixCommonModules ];
        _module.args = {
          inherit system ragenix ragenixKeyPath;
          inherit customConfigs;
        };
      };

      mkNixosConfig = { system, customConfigs, ... }@mkNixosConfigInput: {
        imports = [ ./nixosModules ];
        _module.args = {
          hyprland = mkNixosConfigInput.hyprland;
        };
      };

      mkNixDarwinConfig = { system, customConfigs, ... }@mkNixDarwinConfigInput: {
        imports = [ ./nixDarwinModules ];
        _module.args = {
        };
      };

      ## INFO :: 05/04/2025 :: Common modules for nixOS and NixDarwin
      ## INFO :: Example :: modules that defines utils / configurations to be available in all nixOS / nixDarwin modules
      commonConfigurationModules = [
        base16utils.nixosModule
        ragenix.nixosModules.default
        ./configurations
      ];
      


      # mkDarwinSystem = {system, user, hostname, ragenix, ragenixKeyPath, ... }@mkDarwinSystemInputs: 
      #   let
      #     hostOptions = (import mkDarwinSystemInputs.hostOptionsPath) { 
      #       config = mkDarwinSystemInputs.flakeInputs.config;
      #       lib = mkDarwinSystemInputs.flakeInputs.nixpkgs.lib;
      #     };
      #   in
      #   darwin.lib.darwinSystem {
      #     inherit system;
      #     modules = commonConfigurationModules ++ [
      #       mkDarwinSystemInputs.hostConfigPath
      #       mkDarwinSystemInputs.stylix.darwinModules.stylix
      #       (mkCommonOsConfig {
      #          inherit system ragenixKeyPath;
      #          ragenix = mkNixOsSystemInputs.flakeInputs.ragenix;  
      #        })
      #       (mkNixDarwinConfig {inherit system; })
      #       home-manager.darwinModules.home-manager
      #       (mkHomeManagerConfig { inherit user system; })
      #     ];
      #   }
      # ;
      
      mkNixosSystem = {system, user, hostname, ragenixKeyPath, ... }@mkNixOsSystemInputs:
        let
          hostOptions = (import mkNixOsSystemInputs.hostOptionsPath) { 
            config = mkNixOsSystemInputs.flakeInputs.config;
            lib = mkNixOsSystemInputs.flakeInputs.nixpkgs.lib;
          };

          ## ===========================================================================
          # Built options/config resolved with host options
          # theses options will be sent to homeManager / NixOs / NixDarwin / Common modules
          ## ===========================================================================
          customConfigs = let 
            configUtils = (import ./custom-config-generator.nix) {
              config = mkNixOsSystemInputs.flakeInputs.config;
              lib = mkNixOsSystemInputs.flakeInputs.nixpkgs.lib;
            }; 
          in 
            configUtils.buildCustomConfig {cfg = hostOptions;}
          ;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonConfigurationModules ++ [
            mkNixOsSystemInputs.hostConfigPath
            mkNixOsSystemInputs.stylix.nixosModules.stylix
            (mkCommonOsConfig {
              inherit system ragenixKeyPath customConfigs;
              ragenix = mkNixOsSystemInputs.flakeInputs.ragenix;

            })
            (mkNixosConfig {
              inherit system customConfigs;
              hyprland = mkNixOsSystemInputs.flakeInputs.hyprland;
            })
            home-manager.nixosModules.home-manager
            (mkHomeManagerConfig { inherit user system customConfigs; })
          ];
        }
      ;
        
    in {
      darwinConfigurations = {
      #   "mac-m1" = mkDarwinSystem {
      #       inherit stylix;
      #       system = "aarch64-darwin";
      #       user = "karim";
      #       hostname = "karle";
      #   };
      };
      nixosConfigurations = {
        "mastodant1" = mkNixosSystem {
          inherit stylix flakeInputs;
          hostConfigPath = ./hosts/mastodant-1/configuration.nix;
          hostOptionsPath = ./hosts/mastodant-1/options.nix;
          system = "x86_64-linux";
          user = "karim";
          ragenixKeyPath = "/home/karim/.ssh/id_agenix_ed25519";
          hostname = "karle";
        };
      };
    };
}
