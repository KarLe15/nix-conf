{ pkgs, lib, config, customConfigs, ... }@inputs : 
let 
    theme = customConfigs.styleConfigs.themes.apply {inherit pkgs; };
    cursor = customConfigs.styleConfigs.cursors.apply {inherit pkgs; };
    fonts = customConfigs.styleConfigs.fonts.apply {inherit pkgs; };
    wallpaper = customConfigs.styleConfigs.wallpaper.apply {inherit pkgs; };
in {
    stylix.base16Scheme = theme.base16-schemes-yaml;
    stylix.fonts = with pkgs; {
        serif = {
            package = fonts.serif.package;
            name = fonts.serif.exact-name;
        };
        sansSerif = {
            package = fonts.sansSerif.package;
            name = fonts.sansSerif.exact-name;
        };
        monospace = {
            package = fonts.mono.package;
            name = fonts.mono.exact-name;
        };
        emoji = {
            package = fonts.emoji.package;
            name = fonts.emoji.exact-name;
        };
    };

    stylix.cursor = {
        package = cursor.default.package;
        name = cursor.default.exact-name;
        size = cursor.default.size;
    };
    
    stylix.image = wallpaper.default.path;
}
