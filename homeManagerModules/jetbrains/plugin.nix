

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
    "com.anthropic.code.plugin"
  ];

in
{
  ## Update 2026-01-24 :
  # nix-jetbrains-plugins: `lib.x86_64-linux.buildIdeWithPlugins` is deprecated. Please switch to `lib.buildIdeWithPlugins`. Note the new function expects `pkgs` instead of `pkgs.jetbrains`
  # 'jetbrains.idea-ultimate' has been renamed to/replaced by 'jetbrains.idea'
  home.packages = with nix-jetbrains-plugins.lib; [
    (buildIdeWithPlugins pkgs "idea" (allCommonPlugins ++ IdeaPlugins))
    (buildIdeWithPlugins pkgs "rust-rover" allCommonPlugins)
    (buildIdeWithPlugins pkgs "webstorm" allCommonPlugins)
    (buildIdeWithPlugins pkgs "goland" allCommonPlugins)
    (buildIdeWithPlugins pkgs "clion" allCommonPlugins)
  ];

}
