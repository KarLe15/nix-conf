{
  apply = {pkgs, monitors, ... }@inputs: 
  let
    mod = "ALT";
    mod-shift = "ALT_SHIFT";
  in 
  {
    workspaces_defined = [
      {id = 1; icon = ""; shortcut = ["A" "KP_1"]; monitor = monitors.disposition.code;       inherit mod mod-shift;} 
      {id = 4; icon = "󰇮"; shortcut = ["Q" "KP_4"]; monitor = monitors.disposition.code;       inherit mod mod-shift;}
      {id = 7; icon = "󰗃"; shortcut = ["W" "KP_7"]; monitor = monitors.disposition.code;       inherit mod mod-shift;}
      
      {id = 2; icon = ""; shortcut = ["Z" "KP_2"]; monitor = monitors.disposition.terminal;   inherit mod mod-shift;}
      {id = 5; icon = ""; shortcut = ["S" "KP_5"]; monitor = monitors.disposition.terminal;   inherit mod mod-shift;}
      {id = 8; icon = ""; shortcut = ["X" "KP_8"]; monitor = monitors.disposition.terminal;   inherit mod mod-shift;}
      
      {id = 3; icon = ""; shortcut = ["E" "KP_3"]; monitor = monitors.disposition.browser;    inherit mod mod-shift;}
      {id = 6; icon = ""; shortcut = ["D" "KP_6"]; monitor = monitors.disposition.browser;    inherit mod mod-shift;}
      {id = 9; icon = ""; shortcut = ["C" "KP_9"]; monitor = monitors.disposition.browser;    inherit mod mod-shift;}

    ];
    navigation = [
      {direction = "Left";  shortcut = ["H" "Left"];    inherit mod mod-shift;}
      {direction = "Down";  shortcut = ["j" "Down"];    inherit mod mod-shift;}
      {direction = "Up";    shortcut = ["k" "Up"];      inherit mod mod-shift;}
      {direction = "Right"; shortcut = ["l" "Right"];   inherit mod mod-shift;}
    ];
  };
  autostart = [
  ];
}