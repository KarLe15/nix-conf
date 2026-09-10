{ pkgs, lib, config, customConfigs, ... }@inputs : 
let 
    theme = customConfigs.styleConfigs.themes.apply {inherit pkgs; };
    cursor = customConfigs.styleConfigs.cursors.apply {inherit pkgs; };
    fonts = customConfigs.styleConfigs.fonts.apply {inherit pkgs; };
    wallpaper = customConfigs.styleConfigs.wallpaper.apply {inherit pkgs; };
in {
    stylix.base16Scheme = theme.base16-schemes-yaml;
    ## Declares the light/dark preference for apps that read it rather than the
    ## palette: gsettings color-scheme -> xdg-desktop-portal -> Firefox/Brave and
    ## any site using prefers-color-scheme. Without it stylix defaults to
    ## polarity = "either" and publishes "no preference", which renders light.
    stylix.polarity = theme.polarity;
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
