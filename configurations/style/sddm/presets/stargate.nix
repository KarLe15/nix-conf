## =======================================================================================
##  SDDM greeter preset :: "Stargate"
##
##  The gate room of SGC, spread over the three monitors. Nix side of the
##  "Login Manager Stargate" design.
##
##    gate       the greeter proper — clock, the Stargate, the dial sequence log
##               and the session picker. Typing codes chevrons; Enter locks the
##               seventh and submits.
##    dhd        dial-home device with its idle shimmer, the saved addresses and
##               the last login. Display only.
##    telemetry  three E2PZ modules and the MALP environment board. Display only.
##
##  SDDM creates one QQuickView — and one QML engine — per monitor, so the three
##  screens hold no shared state and only the gate takes keyboard input. That is
##  why the roles below are per connector rather than a single mirrored layout.
##
##  Every value here is serialized into the theme's generated Theme.qml /
##  Config.qml by nixosModules/sddm-stargate. Colours are Theme palette *names*
##  and icons are Nerd Font codepoints (hex, no backslash, emitted as \uXXXX) —
##  the same conventions the quickshell presets use.
##
##             +----------------+
##             |    HDMI-A-2    |     gate · 3440x1440
##             +----------------+
##       +-----------+  +-----------+
##       |   DP-3    |  |   DP-1    |
##       |    dhd    |  | telemetry |
##       +-----------+  +-----------+
##
## =======================================================================================
{
  apply = { pkgs, ... }: {
    ## Which connector draws which screen. Names come from DRM and are what
    ## Screen.name reports to the greeter, so they match the monitors preset.
    screens = {
      gate      = "HDMI-A-2";
      dhd       = "DP-3";
      telemetry = "DP-1";
    };

    ## Palette names, resolved against Theme.qml in QML.
    ##   chevron  a chevron that has engaged, and the dialling accent
    ##   horizon  the event horizon once chevron seven locks
    ##   error    a cancelled dial (wrong password)
    ##   caps     caps lock is on
    colors = {
      chevron = "peach";
      horizon = "blue";
      error   = "red";
      caps    = "yellow";
    };

    ## The show's gate: 39 glyphs on the inner ring, nine chevrons, 40 degrees of
    ## ring travel per coded glyph. `maxPreLock` is deliberately below seven —
    ## see the option description, it bounds what the chevrons say about the
    ## password's length.
    gate = {
      diameter      = 760;
      chevronRadius = 352;
      symbolSlots   = 39;
      degPerChar    = 40;
      maxPreLock    = 6;
      dialMs        = 800;
    };

    dhd = {
      diameter  = 760;
      keys      = 19;
      shimmerMs = 2000;
      origin    = "P3X-984";
    };

    clock24 = true;

    ## The host runs LANG=en_US with French LC_* overrides, but the greeter runs
    ## as the `sddm` user and inherits neither — so the locale is named here.
    locale = "fr_FR";

    ## Chrome glyphs. Per-row glyphs for the ambience screens live with their
    ## rows in the theme's MissionData.qml.
    icons = {
      distro   = "f313";  # nf-linux-nixos
      user     = "f007";  # nf-fa-user
      keyboard = "f11c";  # nf-fa-keyboard_o
      lock     = "f023";  # nf-fa-lock
      submit   = "f078";  # nf-fa-chevron_down
      caps     = "f071";  # nf-fa-warning
      suspend  = "f186";  # nf-fa-moon_o
      reboot   = "f021";  # nf-fa-refresh
      power    = "f011";  # nf-fa-power_off
      readOnly = "f06e";  # nf-fa-eye — marks the two ambience screens
    };

    ## "Destination" picker. Keys are session names lowercased; `default` covers
    ## anything the host exposes that is not listed.
    sessionIcons = {
      hyprland = "f009";  # nf-fa-th_large
      niri     = "f0db";  # nf-fa-columns
      gnome    = "f108";  # nf-fa-desktop
      plasma   = "f2d0";  # nf-fa-window_maximize
      default  = "f2d0";
    };
  };

  autostart = [
  ];
}
