## =======================================================================================
##
##                  +----------------+ 
##                  |       Top      | 
##              200 |  3440 * 1440   | 200
##                  +----------------+ 
##              +-----------+ +-----------+
##              |   Left    | |    Right  |
##              | 1920*1080 | | 1920*1080 |
##              +-----------+ +-----------+
##              |---------< 3840 >--------|  
##
##
## =======================================================================================
{
  apply = {pkgs, ... }: {
    definition = [
      ## Left Monitor
      {
        name = "DP-3";
        width = 1920;
        height = 1080;
        refreshRate = 60;
        position = { x = 0; y = 1440; };
        scale = 1;
        primary = true;
      }
      ## Top Monitor
      {
        name = "HDMI-A-2";
        width = 3440;
        height = 1440;
        refreshRate = 100;
        scale = 1;
        position = { x = 200; y = 0; };
      }
      ## Right Monitor
      {
        name = "DP-1";
        width = 1920;
        height = 1080;
        refreshRate = 60;
        scale = 1;
        position = { x = 1920; y = 1440; };
      }
    ];
    disposition = {
      code = "DP-3";
      terminal = "DP-1";
      browser = "HDMI-A-2";
    };
  };   
}