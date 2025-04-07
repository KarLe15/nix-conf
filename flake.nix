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
    
    stylix.url = "github:danth/stylix";

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

  outputs = { self, nixpkgs, nixpkgs-darwin, darwin, home-manager, stylix, hyprland, base16utils, ... }@flakeInputs :
  let 
    mkHomeManagerConfig = { user, system, hostOptions, ... }@mkHomeManagerConfigInputs: {
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
          ## TODO :: 06/04/2024 :: Home-Manager module not merged into home-manager repo 
          ## Using Custom Home-manager module defined by KarLe
          # walker.homeManagerModules.default 
        ];
      };
      home-manager.extraSpecialArgs =  {
        hardwareConfigs = self.hardwareConfigsGenerator { cfg = hostOptions; };
        styleConfigs = self.styleConfigsGenerator { cfg = hostOptions; };
        softwareConfigs = self.softwareConfigsGenerator { cfg = hostOptions; };
      };
    };

    mkCommonOsConfig = { system, hostOptions , ... }@mkCommonOsConfigInput: {
      imports = [ ./nixCommonModules ];
      _module.args = {
        hardwareConfigs = self.hardwareConfigsGenerator { cfg = hostOptions; };
        styleConfigs = self.styleConfigsGenerator { cfg = hostOptions; };
        softwareConfigs = self.softwareConfigsGenerator { cfg = hostOptions; };
      };
    };

    mkNixosConfig = { system, hostOptions, ... }@mkNixosConfigInput: {
      imports = [ ./nixosModules ];
      _module.args = {
        hyprland = mkNixosConfigInput.hyprland;
      };
    };

    mkNixDarwinConfig = { system, hostOptions , ... }@mkNixDarwinConfigInput: {
      imports = [ ./nixDarwinModules ];
      _module.args = {
      };
    };

    ## INFO :: 05/04/2025 :: Common modules for nixOS and NixDarwin
    ## INFO :: Example :: modules that defines utils / configurations to be available in all nixOS / nixDarwin modules
    commonConfigurationModules = [
      base16utils.nixosModule
      ./configurations
    ];
    


    # mkDarwinSystem = {system, user, hostname, ... }@mkDarwinSystemInputs: 
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
    #       (mkCommonOsConfig {inherit system hostOptions; })
    #       (mkNixDarwinConfig {inherit system hostOptions; })
    #       home-manager.darwinModules.home-manager
    #       (mkHomeManagerConfig { inherit user system hostOptions; })
    #     ];
    #   }
    # ;
    
    mkNixosSystem = {system, user, hostname, ... }@mkNixOsSystemInputs:
      let
        hostOptions = (import mkNixOsSystemInputs.hostOptionsPath) { 
          config = mkNixOsSystemInputs.flakeInputs.config;
          lib = mkNixOsSystemInputs.flakeInputs.nixpkgs.lib;
        };
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonConfigurationModules ++ [
          mkNixOsSystemInputs.hostConfigPath
          mkNixOsSystemInputs.stylix.nixosModules.stylix
          (mkCommonOsConfig {inherit system hostOptions; })
          (mkNixosConfig {
            inherit system hostOptions;
            hyprland = mkNixOsSystemInputs.flakeInputs.hyprland;
          })
          home-manager.nixosModules.home-manager
          (mkHomeManagerConfig { inherit user system hostOptions; })
        ];
      }
    ;
      
  in {

    hardwareConfigsGenerator = { cfg, ... }: 
      let
        hw = cfg.hardware;
      in {
        monitors = import ./configurations/hardware/monitors/presets/${hw.monitors.active}.nix;
      }
    ;

    styleConfigsGenerator = { cfg, ... } : 
      let
        style = cfg.style;
      in {
        themes = import ./configurations/style/themes/presets/${style.themes.active}.nix;
        cursors = import ./configurations/style/cursors/presets/${style.cursors.active}.nix;
        fonts = import ./configurations/style/fonts/presets/${style.fonts.active}.nix;
        wallpaper = import ./configurations/style/wallpapers/presets/${style.wallpaper.active}.nix;
      }
    ;

    softwareConfigsGenerator = {cfg, ... }: 
      let
        sw = cfg.software;
      in {
        defaults = import ./configurations/software/defaults/presets/${sw.defaults.active}.nix;
        developpement = import ./configurations/software/developpement/presets/${sw.developpement.active}.nix;
        shortcuts = import ./configurations/software/shortcuts/presets/${sw.shortcuts.active}.nix;
        launchers = import ./configurations/software/launchers/presets/${sw.launchers.active}.nix;
        modules = {
          eww.enable = false;
          walker.enable = true;
        };
      }
    ;

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
        hostname = "karle";
      };
    };
  };
}
