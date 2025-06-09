{pkgs, lib, config, customConfigs, ... } :
let
  cfg = customConfigs.softwareConfigs.modules.walker;
  system-theme = customConfigs.styleConfigs.themes.apply {inherit pkgs; };
  base16-theme = config.lib.base16.mkSchemeAttrs system-theme.base16-schemes-yaml;
  theme-name = "karle-theme";
in  {

  services.walker = lib.mkIf cfg.enable {
    enable = true;
    
    # Main Walker configuration
    settings = {
      # Top-level settings
      app_launch_prefix = "uwsm app -- ";
      close_when_open = false;
      theme = theme-name;
      as_window = false;
      
      # Keys configuration
      keys = {
        accept_typeahead = ["tab"];
        next = ["down"];
        prev = ["up"];
        close = ["esc"];
        
        activation_modifiers = {
          keep_open = "shift";
          alternate = "alt";
        };
      };
      
      # List settings
      list = {
        max_entries = 50;
        show_initial_entries = true;
        single_click = true;
      };
      
      # Search settings
      search = {
        placeholder = "Search...";
        delay = 0;
      };
      
      # Basic builtins configuration
      builtins = {
        applications = {
          weight = 5;
          name = "applications";
          placeholder = "Applications";
          show_icon_when_single = true;
        };
        calculator = {
          weight = 5;
          name = "calc";
          placeholder = "Calculator";
        };
        websearch = {
          weight = 5;
          name = "websearch";
          placeholder = "Web Search";
          entries = [
            # {
            #   name = "Google";
            #   url = "https://www.google.com/search?q=%TERM%";
            # }
            # {
            #   name = "DuckDuckGo";
            #   url = "https://duckduckgo.com/?q=%TERM%";
            # }
          ];
        };
      };
    };
    
    # Theme configuration
    theme = {
      name = theme-name;
      toml =  {
        ui = {
          anchors = {
            bottom = true;
            left = true;
            right = true;
            top = true;
          };
          window = {
            h_align = "fill";
            v_align = "fill";
            box = {
              h_align = "center";
              width = 450;
              bar = {
                orientation = "horizontal";
                position = "end";
                entry = {
                  h_align = "fill";
                  h_expand = true;
                  icon = {
                    h_align = "center";
                    h_expand = true;
                    pixel_size = 24;
                    theme = "";
                  };
                };
              };
              margins = {
                top = 200;
              };
              ai_scroll = {
                name = "aiScroll";
                h_align = "fill";
                v_align = "fill";
                max_height = 300;
                min_width = 400;
                height = 300;
                width = 400;
                margins = {
                  top = 8;
                };
                list = {
                  name = "aiList";
                  orientation = "vertical";
                  width = 400;
                  spacing = 10;
                  item = {
                    name = "aiItem";
                    h_align = "fill";
                    v_align = "fill";
                    x_align = 0;
                    y_align = 0;
                    wrap = true;
                  };
                };
              };
              scroll = {
                list = {
                  marker_color = "#${base16-theme.base0C}";
                  max_height = 300;
                  max_width = 400;
                  min_width = 400;
                  width = 400;
                  item = {
                    activation_label = {
                      h_align = "fill";
                      v_align = "fill";
                      width = 20;
                      x_align = 0.5;
                      y_align = 0.5;
                    };
                    icon = {
                      pixel_size = 26;
                      theme = "";
                    };
                  };
                  margins = {
                    top = 8;
                  };
                };
              };
              search = {
                prompt = {
                  name = "prompt";
                  icon = "edit-find";
                  theme = "";
                  pixel_size = 18;
                  h_align = "center";
                  v_align = "center";
                };
                clear = {
                  name = "clear";
                  icon = "edit-clear";
                  theme = "";
                  pixel_size = 18;
                  h_align = "center";
                  v_align = "center";
                };
                input = {
                  h_align = "fill";
                  h_expand = true;
                  icons = true;
                };
                spinner = {
                  hide = true;
                };
              };
            };
          };
        };
      };
      css.base16-colors = base16-theme;
    };
  };
}