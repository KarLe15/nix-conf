{ pkgs, lib, config, styleConfigs, ... }@inputs : 
let 
    theme = builtins.trace "NixOsModule content: ${(builtins.toJSON (builtins.attrNames config.lib.base16 ))}" styleConfigs.themes.apply {inherit pkgs; };
    cursor = styleConfigs.cursors.apply {inherit pkgs; };
in {
    stylix.base16Scheme = theme.base16-schemes-yaml;
    stylix.fonts = with pkgs; {
        serif = {
            package = dejavu_fonts;
            name = "DejaVu Serif";
        };

        sansSerif = {
            package = dejavu_fonts;
            name = "DejaVu Sans";
        };

        monospace = {
            package = dejavu_fonts;
            name = "DejaVu Sans Mono";
        };

        emoji = {
            package = noto-fonts-emoji;
            name = "Noto Color Emoji";
        };
    };

    stylix.cursor = {
        package = cursor.default.package;
        name = cursor.default.exact-name;
        size = cursor.default.size;
    };
}
