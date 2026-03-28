## =============================================================================
##  Preset output type definitions (Phase 3 — Option B)
##
##  Each type describes the shape of what a preset's `apply` function must
##  return.  These types are used in custom-config-generator.nix to wrap
##  every preset's apply function so that type errors are reported at
##  evaluation time rather than as cryptic missing-attribute errors deep in
##  a Home Manager module.
##
##  Usage:
##    let types = import ./configurations/types.nix { inherit lib; };
##    in types.monitorsOutputType   # lib.types.submodule value
## =============================================================================
{ lib }:
let

  # ---------------------------------------------------------------------------
  # Shared leaf types
  # ---------------------------------------------------------------------------

  ## A derivation / store path  (re-exported for convenience)
  packageType = lib.types.package;

  ## { command, name, package }
  appDefType = lib.types.submodule {
    options = {
      command = lib.mkOption {
        type = lib.types.str;
        description = "Shell command to launch the application.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable display name.";
      };
      package = lib.mkOption {
        type = packageType;
        description = "nixpkgs derivation that provides the command.";
      };
    };
  };

  ## { command, name, package, env }  (logout has an extra env field)
  appDefWithEnvType = lib.types.submodule {
    options = {
      command = lib.mkOption { type = lib.types.str; };
      name    = lib.mkOption { type = lib.types.str; };
      package = lib.mkOption { type = packageType; };
      env     = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Optional env-var prefix prepended to the exec command.";
      };
    };
  };

  ## { command }
  powerCommandType = lib.types.submodule {
    options = {
      command = lib.mkOption {
        type = lib.types.str;
        description = "Shell command for this power action.";
      };
    };
  };

  ## { description, command }
  mediaCommandType = lib.types.submodule {
    options = {
      description = lib.mkOption { type = lib.types.str; };
      command     = lib.mkOption { type = lib.types.str; };
    };
  };

  ## { command, name, package }  (same shape as appDefType, aliased for clarity)
  launcherDefType = appDefType;

  ## { group-name, exact-name, package }
  fontDefType = lib.types.submodule {
    options = {
      group-name = lib.mkOption {
        type = lib.types.str;
        description = "Font family name.";
      };
      exact-name = lib.mkOption {
        type = lib.types.str;
        description = "Exact PostScript font name passed to Stylix / fontconfig.";
      };
      package = lib.mkOption { type = packageType; };
    };
  };

  ## { group-name, exact-name, size, package }
  cursorDefType = lib.types.submodule {
    options = {
      group-name = lib.mkOption { type = lib.types.str; };
      exact-name = lib.mkOption {
        type = lib.types.str;
        description = "Exact cursor theme name passed to hyprctl setcursor.";
      };
      size    = lib.mkOption { type = lib.types.int; };
      package = lib.mkOption { type = packageType; };
    };
  };

  ## { x, y }
  positionType = lib.types.submodule {
    options = {
      x = lib.mkOption { type = lib.types.int; };
      y = lib.mkOption { type = lib.types.int; };
    };
  };

  ## Single monitor record
  monitorDefType = lib.types.submodule {
    options = {
      name        = lib.mkOption { type = lib.types.str; description = "Kernel device name, e.g. \"HDMI-A-2\"."; };
      width       = lib.mkOption { type = lib.types.int; };
      height      = lib.mkOption { type = lib.types.int; };
      refreshRate = lib.mkOption { type = lib.types.int; };
      position    = lib.mkOption { type = positionType; };
      ## Accept int (e.g. 1) or float (e.g. 1.5) — Nix integer literals satisfy
      ## neither lib.types.float nor lib.types.number on some nixpkgs versions,
      ## so we explicitly allow either.
      scale       = lib.mkOption { type = lib.types.either lib.types.int lib.types.float; };
      primary     = lib.mkOption { type = lib.types.bool; default = false; };
    };
  };

in
{
  # ---------------------------------------------------------------------------
  # hardware/monitors  apply output type
  # ---------------------------------------------------------------------------
  monitorsOutputType = lib.types.submodule {
    options = {
      definition = lib.mkOption {
        type = lib.types.listOf monitorDefType;
        description = "Ordered list of monitor configuration records.";
      };
      disposition = lib.mkOption {
        type = lib.types.submodule {
          options = {
            code     = lib.mkOption { type = lib.types.str; description = "Monitor name for code/IDE workspaces."; };
            terminal = lib.mkOption { type = lib.types.str; description = "Monitor name for terminal workspaces."; };
            browser  = lib.mkOption { type = lib.types.str; description = "Monitor name for browser workspaces."; };
          };
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # style/themes  apply output type
  # ---------------------------------------------------------------------------
  themesOutputType = lib.types.submodule {
    options = {
      base16-schemes-yaml = lib.mkOption {
        type = lib.types.path;
        description = "Path to a base16-compatible YAML color scheme file.";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # style/fonts  apply output type
  # ---------------------------------------------------------------------------
  fontsOutputType = lib.types.submodule {
    options = {
      mono      = lib.mkOption { type = fontDefType; };
      serif     = lib.mkOption { type = fontDefType; };
      sansSerif = lib.mkOption { type = fontDefType; };
      emoji     = lib.mkOption { type = fontDefType; };
    };
  };

  # ---------------------------------------------------------------------------
  # style/cursors  apply output type
  # ---------------------------------------------------------------------------
  cursorsOutputType = lib.types.submodule {
    options = {
      default = lib.mkOption { type = cursorDefType; };
    };
  };

  # ---------------------------------------------------------------------------
  # style/wallpapers  apply output type
  # ---------------------------------------------------------------------------
  wallpaperOutputType = lib.types.submodule {
    options = {
      default = lib.mkOption {
        type = lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.path;
              description = "Absolute path to the wallpaper image file.";
            };
          };
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # software/defaults  apply output type
  # ---------------------------------------------------------------------------
  defaultsOutputType = lib.types.submodule {
    options = {
      browser             = lib.mkOption { type = appDefType; };
      terminal            = lib.mkOption { type = appDefType; };
      terminal-editor     = lib.mkOption { type = appDefType; };
      file-explorer       = lib.mkOption { type = appDefType; };
      email               = lib.mkOption { type = appDefType; };
      notification-center = lib.mkOption { type = appDefType; };
      logout              = lib.mkOption { type = appDefWithEnvType; };
      lockscreen          = lib.mkOption { type = appDefType; };
      idlemanager         = lib.mkOption { type = appDefType; };
      audiomanager        = lib.mkOption { type = appDefType; };
    };
  };

  # ---------------------------------------------------------------------------
  # software/launchers  apply output type
  # ---------------------------------------------------------------------------
  launchersOutputType = lib.types.submodule {
    options = {
      applications = lib.mkOption { type = launcherDefType; };
      clipboard    = lib.mkOption { type = launcherDefType; };
    };
  };

  # ---------------------------------------------------------------------------
  # software/multimedia  apply output type
  # ---------------------------------------------------------------------------
  multimediaOutputType = lib.types.submodule {
    options = {
      increaseVolume = lib.mkOption { type = mediaCommandType; };
      lowerVolume    = lib.mkOption { type = mediaCommandType; };
      toggleVolume   = lib.mkOption { type = mediaCommandType; };
    };
  };

  # ---------------------------------------------------------------------------
  # software/powermanagement  apply output type
  # ---------------------------------------------------------------------------
  powermanagementOutputType = lib.types.submodule {
    options = {
      commands = lib.mkOption {
        type = lib.types.submodule {
          options = {
            shutdown  = lib.mkOption { type = powerCommandType; };
            reboot    = lib.mkOption { type = powerCommandType; };
            suspend   = lib.mkOption { type = powerCommandType; };
            hibernate = lib.mkOption { type = powerCommandType; };
          };
        };
      };
      programs = lib.mkOption {
        type = lib.types.listOf packageType;
        default = [];
      };
    };
  };

  # ---------------------------------------------------------------------------
  # software/developpement  apply output type
  # ---------------------------------------------------------------------------
  developpementOutputType = lib.types.submodule {
    options = {
      apiClient = lib.mkOption { type = appDefType; };
    };
  };

  # ---------------------------------------------------------------------------
  # software/git-accounts  apply output type
  # ---------------------------------------------------------------------------
  gitAccountDefType = lib.types.submodule {
    options = {
      username   = lib.mkOption { type = lib.types.str; };
      email      = lib.mkOption { type = lib.types.str; };
      key        = lib.mkOption { type = lib.types.path; description = "Path to SSH private key."; };
      dns-alias  = lib.mkOption { type = lib.types.str; description = "SSH Host alias, e.g. \"github-perso\"."; };
      dns-origin = lib.mkOption { type = lib.types.str; description = "Real SSH hostname, e.g. \"github.com\"."; };
    };
  };

  gitAccountsOutputType = lib.types.submodule {
    options = {
      defaultEditor = lib.mkOption { type = lib.types.str; };
      enableAliases = lib.mkOption { type = lib.types.bool; default = false; };
      git-accounts  = lib.mkOption { type = lib.types.listOf lib.types.attrs; };
    };
  };
}
