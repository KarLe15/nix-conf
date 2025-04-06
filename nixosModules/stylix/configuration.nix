{ pkgs, lib, config, styleConfigs, ... }@inputs : 
let 
    theme = styleConfigs.themes.apply {inherit pkgs; };
    cursor = styleConfigs.cursors.apply {inherit pkgs; };
    fonts = styleConfigs.fonts.apply {inherit pkgs; };
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
}
