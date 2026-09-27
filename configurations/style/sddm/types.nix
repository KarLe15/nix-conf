{ lib }:
{
  sddmOutputType = lib.types.submodule {
    options = {
      screens = lib.mkOption {
        type = lib.types.submodule {
          options = {
            gate = lib.mkOption {
              type        = lib.types.str;
              description = "Connector carrying the interactive greeter (the Stargate).";
            };
            dhd = lib.mkOption {
              type        = lib.types.str;
              description = "Connector carrying the dial-home device (display only).";
            };
            telemetry = lib.mkOption {
              type        = lib.types.str;
              description = "Connector carrying the E2PZ + MALP board (display only).";
            };
          };
        };
        description = ''
          Connector name per screen role. Matched against Screen.name at runtime;
          a connector that is absent simply gets no view, and the gate falls back
          to the widest screen so the machine is never left without a login field.
        '';
      };

      colors = lib.mkOption {
        type        = lib.types.attrsOf lib.types.str;
        description = ''
          Theme palette *names* (peach, blue, red, ...), not hex values. They are
          resolved against the generated Theme.qml in QML, so a theme flavor
          change follows without touching this preset.
        '';
      };

      gate = lib.mkOption {
        type = lib.types.submodule {
          options = {
            diameter = lib.mkOption {
              type        = lib.types.int;
              description = "Outer diameter of the gate, in design pixels.";
            };
            chevronRadius = lib.mkOption {
              type        = lib.types.int;
              description = "Distance from the gate centre to a chevron's centre.";
            };
            symbolSlots = lib.mkOption {
              type        = lib.types.int;
              description = "Glyph slots on the inner ring (39 on the show's gate).";
            };
            degPerChar = lib.mkOption {
              type        = lib.types.int;
              description = "Degrees the inner ring turns per typed character.";
            };
            maxPreLock = lib.mkOption {
              type        = lib.types.int;
              description = ''
                Chevrons the typing may light before Enter. Caps how much of the
                password length the screen reveals: 6 means a 20-character
                password looks the same as a 6-character one.
              '';
            };
            dialMs = lib.mkOption {
              type        = lib.types.int;
              description = "Duration of one ring turn, in milliseconds.";
            };
          };
        };
        description = "Gate geometry and dialling behaviour.";
      };

      dhd = lib.mkOption {
        type = lib.types.submodule {
          options = {
            diameter = lib.mkOption {
              type        = lib.types.int;
              description = "Outer diameter of the dial-home device, in design pixels.";
            };
            keys = lib.mkOption {
              type        = lib.types.int;
              description = "Keys per ring; the DHD draws two rings of this count.";
            };
            shimmerMs = lib.mkOption {
              type        = lib.types.int;
              description = "How often the idle key shimmer picks a new lit set.";
            };
            origin = lib.mkOption {
              type        = lib.types.str;
              description = "Point-of-origin address shown on the DHD dome.";
            };
          };
        };
        description = "Dial-home-device geometry and idle animation.";
      };

      clock24 = lib.mkOption {
        type        = lib.types.bool;
        description = "Render the greeter clock on a 24-hour dial.";
      };

      locale = lib.mkOption {
        type        = lib.types.str;
        description = ''
          Locale the greeter formats dates and times in. Set explicitly because
          the greeter runs as the `sddm` user and does not inherit the host's
          LC_TIME.
        '';
      };

      icons = lib.mkOption {
        type        = lib.types.attrsOf lib.types.str;
        description = ''
          Nerd Font codepoints (hex, no backslash) emitted as \uXXXX — the same
          convention the quickshell bar layout uses.
        '';
      };

      sessionIcons = lib.mkOption {
        type        = lib.types.attrsOf lib.types.str;
        description = ''
          Session name (lowercased) -> Nerd Font codepoint, for the "Destination"
          picker. `default` covers any session without an entry.
        '';
      };
    };
  };
}
