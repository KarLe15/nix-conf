# display fields of a set 
Let say in a nix file we use the variable base16-theme defined like this :
```nix
base16-theme = {
  # Base16 Color Scheme
  # A simple Nix set representing the base16 color palette
  # Basic colors
  base00 = "#181818"; # Default Background
  base01 = "#282828"; # Lighter Background
  base02 = "#383838"; # Selection Background
  base03 = "#585858"; # Comments, Invisibles, Line Highlighting
  base04 = "#b8b8b8"; # Dark Foreground
  base05 = "#d8d8d8"; # Default Foreground
  base06 = "#e8e8e8"; # Light Foreground
  base07 = "#f8f8f8"; # Light Background
  
  # Accent colors
  base08 = "#ab4642"; # Red
  base09 = "#dc9656"; # Orange
  base0A = "#f7ca88"; # Yellow
  base0B = "#a1b56c"; # Green
  base0C = "#86c1b9"; # Cyan
  base0D = "#7cafc2"; # Blue
  base0E = "#ba8baf"; # Purple
  base0F = "#a16946"; # Brown
};
```

to be able to print/log any fields of set here is a cool trick to do to avoid the lazy evaluation miss of the print expression
```nix
test = {
  # Base16 Color Scheme
  # A simple Nix set representing the base16 color palette
  # Basic colors
  base00 = "#181818"; # Default Background
  base01 = "#282828"; # Lighter Background
  base02 = "#383838"; # Selection Background
  base03 = "#585858"; # Comments, Invisibles, Line Highlighting
  base04 = "#b8b8b8"; # Dark Foreground
  base05 = "#d8d8d8"; # Default Foreground
  base06 = "#e8e8e8"; # Light Foreground
  base07 = "#f8f8f8"; # Light Background
  
  # Accent colors
  base08 = "#ab4642"; # Red
  base09 = "#dc9656"; # Orange
  base0A = "#f7ca88"; # Yellow
  base0B = "#a1b56c"; # Green
  base0C = "#86c1b9"; # Cyan
  base0D = "#7cafc2"; # Blue
  base0E = "#ba8baf"; # Purple
  base0F = "#a16946"; # Brown
};
base16-theme = builtins.trace "HomeManagerModue content: ${(builtins.toJSON (builtins.attrNames <variable to be printed> ))}" test;
```