{inputs, pkgs, lib, config, hardwareConfigs, styleConfigs, softwareConfigs, ... } : 
let 
  activeMonitorConfig = hardwareConfigs.monitors;
  cursor = styleConfigs.cursors.apply { inherit pkgs; };
  defaults = softwareConfigs.defaults.apply { inherit pkgs; };
  launchers = softwareConfigs.launchers.apply { inherit pkgs; };
  developpement = softwareConfigs.developpement.apply { inherit pkgs; };
  shortcuts-impl = softwareConfigs.shortcuts.shortcuts-definition { inherit defaults developpement launchers ; };
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
  wayland.windowManager.hyprland = {
    enable = true;
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
      bind = (map (shortcut: "${shortcut.mod1}, ${shortcut.key}, ${shortcut.dispatcher-type}, ${shortcut.command}") shortcuts-impl);
      
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
