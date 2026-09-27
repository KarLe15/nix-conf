## =======================================================================================
##  Catppuccin palette :: the one table
##
##  Every surface in this repo that renders a QML Theme reads its colours from here:
##  the bar and the notification server (qml/shell/generate.nix), and the lock screen
##  and the SDDM greeter (qml/stargate/generate.nix).
##
##  It lives outside both of those directories on purpose. The stargate tree is copied
##  wholesale into the greeter theme and the lock config, which is why those consumers
##  `rm -f generate.nix` afterwards; a palette kept in here is never copied and needs
##  no such cleanup.
##
##  Usage:
##    let pal = import ../palette.nix { inherit lib; };
##        palette = pal.forFlavor "quickshell" theme.flavor;
##    in pal.props palette
## =======================================================================================
{ lib }:

let
  palettes = {
    macchiato = {
      rosewater = "#f4dbd6"; flamingo = "#f0c6c6"; pink     = "#f5bde6";
      mauve     = "#c6a0f6"; red      = "#ed8796"; maroon   = "#ee99a0";
      peach     = "#f5a97f"; yellow   = "#eed49f"; green    = "#a6da95";
      teal      = "#8bd5ca"; sky      = "#91d7e3"; sapphire = "#7dc4e4";
      blue      = "#8aadf4"; lavender = "#b7bdf8";
      text      = "#cad3f5"; subtext1 = "#b8c0e0"; subtext0 = "#a5adcb";
      overlay2  = "#939ab7"; overlay1 = "#8087a2"; overlay0 = "#6e738d";
      surface2  = "#5b6078"; surface1 = "#494d64"; surface0 = "#363a4f";
      base      = "#24273a"; mantle   = "#1e2030"; crust    = "#181926";
    };
  };
in
{
  inherit palettes;

  ## `who` only names the caller in the error, so an unsupported flavor says which
  ## surface asked for it rather than just "no palette".
  forFlavor = who: flavor:
    palettes.${flavor}
      or (throw "${who}: no Catppuccin palette defined for theme flavor '${flavor}'");

  ## One `readonly property color <name>: "<hex>"` line per entry, at the indentation
  ## both generators emit their singleton bodies with.
  props = palette: lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (name: hex: "    readonly property color ${name}: \"${hex}\"")
      palette
  );
}
