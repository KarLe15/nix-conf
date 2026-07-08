{ system, inputs, pkgs, nixpkgs, lib, config, customConfigs, nix-jetbrains-plugins, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.jetbrains;

  themePlugins = [
    "com.github.catppuccin.jetbrains"
    "izhangzhihao.rainbow.brackets"
    "com.intellij.ideolog"
    "com.mallowigi"
    "indent-rainbow.indent-rainbow"
    "com.clutcher.comments_highlighter"
  ];
  utilsPlugins = [
    "String Manipulation"
    "com.intellij.tasks"
    "com.github.jk1.ytplugin"
    "nix-idea"
  ];
  allCommonPlugins = themePlugins ++ utilsPlugins;
  ideaPlugins = allCommonPlugins ++ [
    "Lombook Plugin"
    "com.anthropic.code.plugin"
  ];
in {
  config = lib.mkIf cfg.enable {
    home.packages = with nix-jetbrains-plugins.lib; [
      (buildIdeWithPlugins pkgs "idea"       ideaPlugins)
      (buildIdeWithPlugins pkgs "rust-rover" allCommonPlugins)
      (buildIdeWithPlugins pkgs "webstorm"   allCommonPlugins)
      (buildIdeWithPlugins pkgs "goland"     allCommonPlugins)
      (buildIdeWithPlugins pkgs "clion"      allCommonPlugins)
    ];
  };
}
