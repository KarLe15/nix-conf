{ lib, ... }: {
  imports = [
  ];
  options.style.stargate = {
    active = lib.mkOption {
      # Add new values here when adding a preset to ./presets/
      type = lib.types.enum [
        "stargate"
      ];
      default = "stargate";
      description = ''
        Active Stargate preset name — drives both the SDDM greeter and the lock screen.

        The selected preset must export:
          apply :: { pkgs, ... } -> {
            screens      :: attrs;  # connector name per screen role (gate/dhd/telemetry)
            colors       :: attrs;  # Theme palette *names*, resolved in QML
            gate         :: attrs;  # gate geometry + dialling behaviour
            dhd          :: attrs;  # dial-home-device geometry + shimmer
            clock24      :: bool;   # 24-hour clock
            locale       :: str;    # locale the greeter formats dates in
            icons        :: attrs;  # Nerd Font codepoints (hex, no backslash)
            sessionIcons :: attrs;  # session name (lowercased) -> codepoint
          }
          autostart :: [ str ]

        SDDM builds one QQuickView — and therefore one QML engine — per monitor,
        so the three screens cannot share state. `screens` is what decides which
        connector gets the interactive greeter and which get the ambience views.

        The preset is serialized into the theme's generated Theme.qml/Config.qml
        singletons by nixosModules/sddm-stargate. See the header comment in
        ./presets/stargate.nix for what each knob drives.
      '';
    };
  };
}
