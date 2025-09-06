

{system, inputs, pkgs, nixpkgs, lib, config, customConfigs, nix-jetbrains-plugins, ... } : 
let 
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
    # "com.intellij.mermaid"
    "com.intellij.tasks"
    "com.github.jk1.ytplugin"
    "nix-idea"
  ];
  allCommonPlugins = themePlugins ++ utilsPlugins;
  IdeaPlugins = [
    "Lombook Plugin"
  ];

in
{
  home.packages = with nix-jetbrains-plugins.lib.${system}; [
    (buildIdeWithPlugins pkgs.jetbrains "idea-ultimate" (allCommonPlugins ++ IdeaPlugins))
    (buildIdeWithPlugins pkgs.jetbrains "rust-rover" allCommonPlugins)
    (buildIdeWithPlugins pkgs.jetbrains "webstorm" allCommonPlugins)
    (buildIdeWithPlugins pkgs.jetbrains "goland" allCommonPlugins)
    (buildIdeWithPlugins pkgs.jetbrains "clion" allCommonPlugins)
  ];

}
