{inputs, pkgs, lib, config, customConfigs, ... } : 
let 
  activeMonitorConfig = customConfigs.hardwareConfigs.monitors;
  workspaces = customConfigs.styleConfigs.workspaces.apply { inherit pkgs; };
  cursor = customConfigs.styleConfigs.cursors.apply { inherit pkgs; };
  defaults = customConfigs.softwareConfigs.defaults.apply { inherit pkgs; };
  launchers = customConfigs.softwareConfigs.launchers.apply { inherit pkgs; };
  developpement = customConfigs.softwareConfigs.developpement.apply { inherit pkgs; };
  multimedia = customConfigs.softwareConfigs.multimedia.apply { inherit pkgs; };
  shortcuts-impl = customConfigs.softwareConfigs.shortcuts.shortcuts-definition { inherit defaults developpement launchers pkgs multimedia ; };
  autostart-services = 
        customConfigs.softwareConfigs.defaults.autostart 
    ++  customConfigs.softwareConfigs.launchers.autostart 
    ++  customConfigs.softwareConfigs.developpement.autostart
    ++  customConfigs.styleConfigs.themes.autostart
    ++  customConfigs.styleConfigs.cursors.autostart
  ;
in
{
  stylix.targets.hyprland.enable = true;
  ## INFO :: The stylix module enables a systemD module and the uwsm is enabled with sddm and hyprland so the hyprpaper is loaded
  stylix.targets.hyprpaper.enable = true;
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    settings = {

      monitor = map (m: 
        "${m.name}, ${toString m.width}x${toString m.height}@${toString m.refreshRate}, ${toString m.position.x}x${toString m.position.y}, ${toString m.scale}"
      ) activeMonitorConfig;
      
      ## Startup Scripts
      "exec-once" = [
        "hyprctl setcursor ${toString cursor.default.exact-name} ${toString cursor.default.size}"
      ] ++ autostart-services;
      
      general = {
        "gaps_out" = "10,3,5,3";
      };
      
      ## Shortcuts definition
      bind = (
        map (shortcut: 
          if shortcut.command != null && shortcut.command != "" && shortcut.dispatcher-type == "exec" && shortcut.env != "" then 
            "${shortcut.mod1}, ${shortcut.key}, ${shortcut.dispatcher-type}, ${shortcut.env} uwsm app -- ${shortcut.command}"
          else if shortcut.command != null && shortcut.command != "" && shortcut.dispatcher-type == "exec" then
            "${shortcut.mod1}, ${shortcut.key}, ${shortcut.dispatcher-type}, uwsm app -- ${shortcut.command}"
          else 
            "${shortcut.mod1}, ${shortcut.key}, ${shortcut.dispatcher-type}, ${shortcut.command}"
        ) shortcuts-impl
      ) ++
      ## Add workspace shortcut 
      lib.flatten (
        map (workspace:
          (map (key: [
                "${workspace.mod}, ${key}, workspace, ${toString workspace.id}"
                "${workspace.mod-shift}, ${key}, movetoworkspacesilent , ${toString workspace.id}"
                ]
            ) 
            workspace.shortcut)
        ) workspaces.workspaces_defined
      )
      ;

      ## https://wiki.hyprland.org/0.48.0/Configuring/Binds/#mouse-binds
      bindm = [
        "ALT, mouse:272, movewindow"
        "ALT, mouse:273, resizewindow"
      ];
      windowrule = [
        "float, class:com.gabm.satty"
        "decorate on, class:com.gabm.satty"
        "bordersize 40, class:com.gabm.satty"
      ];

      ## https://wiki.hyprland.org/0.48.0/Configuring/Workspace-Rules/
      workspace = [
          "1, monitor:DP-3"
          "4, monitor:DP-3"
          "7, monitor:DP-3"
          "2, monitor:DP-1"
          "5, monitor:DP-1"
          "8, monitor:DP-1"
          "3, monitor:HDMI-A-2"
          "6, monitor:HDMI-A-2"
          "9, monitor:HDMI-A-2"
      ];


      input = {
        "kb_layout" = "fr";
        "numlock_by_default" = "true";
      };
      
      misc =  {

      };
      
      cursor = {

      };
        
    };
  };
}
