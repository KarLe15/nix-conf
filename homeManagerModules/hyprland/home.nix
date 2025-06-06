{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  activeMonitorConfig = hardwareConfigs.monitors;
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
  defaults = softwareConfigs.defaults.apply { inherit pkgs; };
  launchers = softwareConfigs.launchers.apply { inherit pkgs; };
  developpement = softwareConfigs.developpement.apply { inherit pkgs; };
  multimedia = softwareConfigs.multimedia.apply { inherit pkgs; };
  shortcuts-impl = softwareConfigs.shortcuts.shortcuts-definition { inherit defaults developpement launchers pkgs multimedia ; };
  autostart-services = 
        softwareConfigs.defaults.autostart 
    ++  softwareConfigs.launchers.autostart 
    ++  softwareConfigs.developpement.autostart
    ++  styleConfigs.themes.autostart
    ++  styleConfigs.cursors.autostart
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
      # "$mod" = "ALT";

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
      );
      
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
