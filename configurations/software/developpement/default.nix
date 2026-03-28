{ lib, config, ... } : {
  imports = [
  ];
  options.software.developpement = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "opensource"
      ];
      default = "opensource";
      description = ''
        Active development tooling preset name. Defines API clients and dev tools
        whose commands may appear in shortcuts or autostarts.

        The selected preset must export:
          apply :: { pkgs } -> {
            apiClient :: AppDef;   # REST/API client
          }
          autostart :: [ str ]

        AppDef :: {
          command :: str;
          name    :: str;
          package :: pkg;
        }
      '';
    };
  };
}