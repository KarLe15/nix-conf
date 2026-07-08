{ lib, config, ... } : {
  imports = [
  ];
  options.software.git-accounts = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "standard"
      ];
      default = "standard";
      description = ''
        Active git accounts preset name. Defines SSH identities and git settings.
        Consumed by the git-accounts Home Manager module.

        The selected preset must export:
          apply :: { pkgs, default-programs } -> {
            defaultEditor :: str;          # git core.editor command
            enableAliases :: bool;
            git-accounts  :: [ GitAccountDef ];
          }
          autostart :: [ str ]

        GitAccountDef :: {
          username   :: str;   # git username
          email      :: str;   # commit email
          key        :: path;  # path to SSH private key (managed by ragenix)
          dns-alias  :: str;   # SSH Host alias, e.g. "github-perso"
          dns-origin :: str;   # real hostname, e.g. "github.com"
        }
      '';
    };
  };
}