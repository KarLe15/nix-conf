{
  apply = {pkgs, default-programs, multimedia-programs, workspaces, ... }@inputs: 
  let
    workspaces_data = {
      workspaces = workspaces.workspaces_defined;
    };
    wireplumber_config = {
      toggle_mute_volume_command = multimedia-programs.toggleVolume.command;
      default_sound_manager_command = default-programs.audiomanager.command;
      increase_volume_command = multimedia-programs.increaseVolume.command;
      lower_volume_command = multimedia-programs.lowerVolume.command;
    };
    clock_data = {
      all_timezones = ["Europe/Paris" "Africa/Algiers"];
      default_timezone = "Europe/Paris";
    };
  in 
  {
    style-file = ../assets/style.css;
    bars = [
      {
        name = "ts-top";
        position = "top";
        screen = "HDMI-A-2";
        spacing = 16;
        modules_left = [
          {
            type    = "clock";
            id      = "clock";
            config  = clock_data;
          }
          {
            type    = "privacy";
            id      = "privacy";
            config  = {};
          }
        ];
        modules_center = [
          {
            type    = "workspaces";
            id      = "hyprland/workspaces";
            config  = workspaces_data;
          }
        ];
        modules_right = [
          {
            type    = "network";
            id      = "network#standard";
            config  =  { display = "standard"; };
          }
          {
            type    = "bluetooth";
            id      = "bluetooth";
            config  = {};
          }  
          {
            type    = "wireplumber";
            id      = "wireplumber";
            config  =  wireplumber_config;
          }
          {
            type    = "cpu";
            id      = "cpu";
            config  = {};
          }
          {
            type    = "memory";
            id      = "memory";
            config  = {};
          }
        ];
      }
      {
        name = "ts-right";
        position = "right";
        screen = "HDMI-A-2";
        mode = "dock";
        spacing = 8;
        modules_left = []; #["gamemode"];
        modules_center = [];
        modules_right = [
          {
            type    = "group";
            id      = "group/utils";
            config  = {
              orientation = "inherit";
              transition_duration = 500;
              transition_left_to_right = false;
              click_to_reveal = false;
              sub_modules = [
                {
                  type    = "image";
                  id      = "image#utils-display";
                  config  = {
                    path = ../assets/stargate-animated.png;
                    size = 96;
                  };
                }
                {
                  type    = "network";
                  id      = "network#drawer";
                  config  = {
                    display = "vertical";
                  };
                }
                {
                  type    = "systemd-failed-display";
                  id      = "systemd-failed-units";
                  config  = {};
                }
                {
                  type    = "wireplumber";
                  id      = "wireplumber";
                  config  =  wireplumber_config;
                }
                {
                  type    = "bluetooth";
                  id      = "bluetooth";
                  config  = {};
                }
              ];
            };
          }
        ];
      }
      {
        name = "ls-top";
        position = "top";
        screen = "DP-3";
        spacing = 8;
        modules_left = [
          {
            type    = "user";
            id      = "user";
            config  = {
              avatar_path = ../assets/profile_oneill.jpg ;
              size = 48;
            }; 
          }
          {
            type    = "custom";
            id      = "custom/openhome";
            config  = {
              format = "󱂵";
              on_click_command = "nautilus $HOME"; # TODO :: change this with default configuration
            };
          }
          {
            type    = "custom";
            id      = "custom/openshared";
            config  = {
              format = "";
              on_click_command = "nautilus $HOME/Downloads"; # TODO :: change this with default configuration
            };
          }
        ];
        modules_center = [
          {
            type    = "workspaces";
            id      = "hyprland/workspaces";
            config  = workspaces_data;
          }
        ];
        modules_right = [
          {
            type    = "network";
            id      = "network#standard";
            config  =  { display = "standard"; };
          }
          {
            type    = "bluetooth";
            id      = "bluetooth";
            config  = {};
          }
          {
            type    = "wireplumber";
            id      = "wireplumber";
            config  =  wireplumber_config;
          }
          {
            type    = "cpu";
            id      = "cpu";
            config  = {};
          }
          {
            type    = "memory";
            id      = "memory";
            config  = {};
          }
        ];
      }
      {
        name = "rs-top";
        position = "top";
        screen = "DP-1";
        spacing = 4;
        modules_left = [
          {
            type    = "clock";
            id      = "clock";
            config  = clock_data;
          }
        ];
        modules_center = [
          {
            type    = "workspaces";
            id      = "hyprland/workspaces";
            config  = workspaces_data;
          }
        ];
        modules_right = [
          {
            type    = "network";
            id      = "network#bandwidth";
            config  =  { display = "bandwidth"; };
          }
        ];
      }
    ];
  };
  autostart = [
  ];
}