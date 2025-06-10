{ pkgs, lib, ... } : 
  let
  
    # ws_config : 
    # {
    #   workspaces = [{id: 1; icon: ""} {id: 2; icon: ""} ...]
    # }
    #
    buildWorkspaceModule = ws_config: {
      "active-only" = false;
      "hide-active" = false;
      "all-outputs" = true;
      format = "{id}: {icon}";
      format-icons = builtins.listToAttrs (
        lib.map (ws: { name = toString ws.id; value = ws.icon; }) 
        ws_config.workspaces
      );
      persistent-workspaces = {
        "*" = lib.map (ws: ws.id) ws_config.workspaces;
      };
    };


    # clock_config : 
    # {
    #   all_timezones = ["Europe/Paris", "Africa/Algiers"];
    #   default_timezone = "Europe/Paris";
    # }
    #
    buildClockModule = clock_config: {
        format = "󱑈 {:%F%t%H:%M%t%Z}";
        max-length = 80;
        interval = 10;
        tooltip-format= "<tt><small>{calendar}</small></tt>";
        calendar = {
            mode           = "month";
            mode-mon-col   = 3;
            weeks-pos      = "right";
            on-scroll      = 1;
            format = {
                months =     "<span color='#a6da95'><b>{}</b></span>";
                days =       "<span color='#f0c6c6'><b>{}</b></span>";
                weeks =      "<span color='#7dc4e4'>  W{}</span>";
                weekdays =   "<span color='#eed49f'><b>{}</b></span>";
                today =      "<span color='#c6a0f6'><b>{}</b></span>";
            };
        };
        actions =  {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
        };
        timezone = clock_config.default_timezone;
        timezones = clock_config.all_timezones;
    };

    # bluetooth_config : 
    # {
    #   on-click-middle = "oversike";
    # }
    #
    buildBluetoothModule = bluetooth_config: {
      on-click-middle = bluetooth_config.on-click-middle;
    };

    buildCpuModule = cpu_config: {
        interval = 15;
        format = " {}%";
        max-length = 10;
        states = {
          warning = 65;
          critical = 85;
        };
    };

    buildMemoryModule = memory_config: {
          interval = 30;
          format = " {}%";
          tooltip-format = " Memory : {used:0.1f} / {total:0.1f} GB \n Swap   : {swapUsed:0.1f} / {swapTotal:0.1f} GB";
          states = {
              warning = 65;
              critical = 85;
          };
          max-length = 10;
    };

    # network_config : 
    # {
    #   display = "vertical" | "standard" | "bandwidth";
    # }
    #
    buildNetworkModule = network_config: 
      if network_config.display == "vertical" then 
        {
          format = " ";
          tooltip-format = "{ifname} via {gwaddr} 󰊗";
          tooltip-format-wifi = "{essid} ({signalStrength}%)  ";
          tooltip-format-ethernet = "{ifname} ";
          tooltip-format-disconnected = "Disconnected";
        }
      else if network_config.display == "bandwidth" then 
        {
          interval = 5;
          format = "󰣺  {signalStrength} %    {bandwidthUpBytes}  -      {bandwidthDownBytes}";
          tooltip = false;
        } 
      else 
        {
          tooltip = false;
          format-wifi = "  {essid}";
          format-ethernet = "󰈀";
        }
    ;

    buildPrivacyModule = privacy_config: {
      icon-spacing = 16;
      icon-size = 32;
      transition-duration = 250;
      modules = [
          {
              type = "screenshare";
              tooltip = true;
              tooltip-icon-size = 24;
          }
          {
              type = "audio-out";
              tooltip = true;
              tooltip-icon-size = 24;
          }
          {
              type = "audio-in";
              tooltip = true;
              tooltip-icon-size = 24;
          }
      ];
    };

    # user_config : 
    # {
    #   avatar_path = ./profile_oneill.jpg;
    #   size = 30
    # }
    #
    buildUserModule = user_config: {
        format = "   {user} (up {work_d} days)";
        interval = 300;
        height = user_config.size;
        width = user_config.size;
        icon = true;
        open-on-click = false;
        avatar = user_config.avatar_path;
    };

    # wireplumber_config : 
    # {
    #   toggle_mute_volume_command = "volumectl -M 0 -d toggle-mute";
    #   default_sound_manager_command = "volumectl -M 0 -d toggle-mute";
    #   increase_volume_command = "volumectl -M 0 -d toggle-mute";
    #   lower_volume_command = "volumectl -M 0 -d toggle-mute";
    # }
    #
    buildWireplumberModule = wireplumber_config: {
      tooltip = false;
      scroll-step = 5;
      format = "{icon}  {volume} %";
      format-muted = "  {volume} %";
      on-click = wireplumber_config.toggle_mute_volume_command;
      on-click-middle = wireplumber_config.default_sound_manager_command;
      on-scroll-up = wireplumber_config.increase_volume_command;
      on-scroll-down = wireplumber_config.lower_volume_command;
      format-icons = {
        default = ["" "" ""];
      };
    };

    # image_config : 
    # {
    #   path = "/home/karim/.config/waybar/profile_oneill.jpg";
    #   size = 48;
    # }
    #
    buildImageModule = image_config: {
      path = image_config.path;
      size = image_config.size;
      tooltip = false;
    };

    buildSystemdUnitStatusModule = systemd_status_config: {
      hide-on-ok = false;
      system = true;
      user = true;
      format = " {nr_failed} ✗";
      format-ok = "✓";
      tooltip = true;
      tooltip-format = "System : ✗  {nr_failed_system}\nUser   : ✗  {nr_failed_user}";
    };

    # custom_config : 
    # {
    #   format = "󱂵";
    #   on_click_command = "nautilus $HOME";
    # }
    #
    buildCustomModule = custom_config: {
      format = custom_config.format;
      on-click = custom_config.on_click_command;
      tooltip = false;
    };

    # group_config : 
    # {
    #   orientation = "inherit"  | "horizontal" | "vertical" | "orthogonal";
    #   transition_duration = 500;
    #   transition_left_to_right = true;
    #   click_to_reveal = true;
    #   sub_modules = [
    #     {
    #       ... config module for each
    #     }      
    #   ];
    # }
    #
    buildGroupModule = group_config: {
      orientation = group_config.orientation;
      drawer = {
        transition-duration = group_config.transition_duration;
        transition-left-to-right = group_config.transition_left_to_right;
        click-to-reveal = group_config.click_to_reveal;
      };
      modules = lib.map (m: m.id) group_config.sub_modules;
    };


    matchModuleBuilder = moduleType: moduleConfig: {
      workspaces                = buildWorkspaceModule          moduleConfig;
      clock                     = buildClockModule              moduleConfig;
      bluetooth                 = buildBluetoothModule          moduleConfig;
      cpu                       = buildCpuModule                moduleConfig;
      memory                    = buildMemoryModule             moduleConfig;
      network                   = buildNetworkModule            moduleConfig;
      privacy                   = buildPrivacyModule            moduleConfig;
      user                      = buildUserModule               moduleConfig;
      wireplumber               = buildWireplumberModule        moduleConfig;
      image                     = buildImageModule              moduleConfig;
      systemd-failed-display    = buildSystemdUnitStatusModule  moduleConfig;
      custom                    = buildCustomModule             moduleConfig;
      group                     = buildGroupModule              moduleConfig;
    }.${moduleType} or (throw "Unknown plugin type: ${moduleType}") ;

    get_sub_modules_from_drawer = modules: 
      let
        group_modules = builtins.filter (m: m.type == "group") modules;
        sub_modules = lib.flatten (lib.map (m: m.config.sub_modules) group_modules);
      in
      if sub_modules == [] then [] else 
        sub_modules ++ (get_sub_modules_from_drawer sub_modules)
    ;
  in
  {
    #
    # bar_config : 
    # {
    #   modules: [
    #     {
    #       type    = "workspaces";
    #       id      = "hyprland/workspaces";
    #       config  =  { ... }
    #     }
    #   ]
    # }
    buildBarObject = bar_config: 
      let 
        left_modules = lib.map (item: item.id) bar_config.modules_left;
        center_modules = lib.map (item: item.id) bar_config.modules_center;
        right_modules = lib.map (item: item.id) bar_config.modules_right;
        all_modules = bar_config.modules_left ++ bar_config.modules_center ++ bar_config.modules_right;
        base_config = {
          spacing = bar_config.spacing;
          name = bar_config.name;
          layer = "top";
          position = bar_config.position;
          output = bar_config.screen;
          modules-left = left_modules;
          modules-center = center_modules;
          modules-right = right_modules;
        };
        sub_modules = get_sub_modules_from_drawer all_modules;
        module_configs = builtins.listToAttrs (
          lib.map 
            (module: { name = module.id; value = matchModuleBuilder module.type module.config; }) 
            all_modules
          )
        ;
        submodule_configs = builtins.listToAttrs ( 
          lib.map 
            (module: { name = module.id; value = matchModuleBuilder module.type module.config; }) 
            sub_modules
          )
        ;
      in     
      # Merge base config with dynamic module configs
      base_config // module_configs // submodule_configs
    ;

  }