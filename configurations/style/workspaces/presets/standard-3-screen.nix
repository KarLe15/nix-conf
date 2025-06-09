{
  apply = {pkgs, ... }@inputs: 
  let
    mod = "ALT";
    mod-shift = "ALT_SHIFT";
  in 
  {
    workspaces_defined = [
      {id = 1; icon = ""; shortcut = ["A" "1"]; inherit mod mod-shift;} 
      {id = 2; icon = ""; shortcut = ["Z" "2"]; inherit mod mod-shift;}
      {id = 3; icon = ""; shortcut = ["E" "3"]; inherit mod mod-shift;}
      {id = 4; icon = "󰇮"; shortcut = ["Q" "4"]; inherit mod mod-shift;}
      {id = 5; icon = ""; shortcut = ["S" "5"]; inherit mod mod-shift;}
      {id = 6; icon = ""; shortcut = ["D" "6"]; inherit mod mod-shift;}
      {id = 7; icon = "󰗃"; shortcut = ["W" "7"]; inherit mod mod-shift;}
      {id = 8; icon = ""; shortcut = ["X" "8"]; inherit mod mod-shift;}
      {id = 9; icon = ""; shortcut = ["C" "9"]; inherit mod mod-shift;}
    ];
  };
  autostart = [
  ];
}