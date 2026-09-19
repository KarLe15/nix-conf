## Launchers backed by the Quickshell command palette rather than rofi.
##
## The shortcuts preset does not use these commands — it fires the palette's
## GlobalShortcut directly via the `global` dispatcher, which avoids a round trip
## through hyprctl. They are kept because the preset contract requires them and
## because they are the answer to "how do I open the launcher from a script".
##
## cliphist is still the clipboard *store*: it captures text and images from the
## autostart watchers below, and the palette's clipboard mode is only the picker.
## Quickshell's own clipboard API is text-only and has no history.
{
  apply = { pkgs, ... }@inputs: {
    applications = {
      command = "hyprctl dispatch 'hl.dsp.global(\"quickshell:palette\")'";
      name = "Quickshell command palette — apps";
      package = pkgs.hyprland;
    };
    clipboard = {
      command = "hyprctl dispatch 'hl.dsp.global(\"quickshell:clipboard\")'";
      name = "Quickshell command palette — clipboard";
      package = pkgs.hyprland;
    };
  };
  autostart = [
    ## Clipboard capture. Still required: the palette picks from this history,
    ## it does not record it.
    "wl-paste --type text --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
  ];
}
