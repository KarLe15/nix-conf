# Window rules
  windowrule = float, class:file_progress
  windowrule = float, class:confirm
  windowrule = float, class:dialog
  windowrule = float, class:download
  windowrule = float, class:notification
  windowrule = float, class:error
  windowrule = float, class:splash
  windowrule = float, class:confirmreset
  windowrule = float, title:Open File
  windowrule = float, title:branchdialog
  windowrule = float, class:zoom
#   windowrule = fullscreen, vlc
  windowrule = float, class:Lxappearance
  windowrule = float, class:ncmpcpp
  windowrule = float, class:Rofi
  windowrule = animation none, class:Rofi
  windowrule = float, class:viewnior
  windowrule = float, class:pavucontrol-qt
  windowrule = float, class:gucharmap
  windowrule = float, class:gnome-font
  windowrule = float, class:org.gnome.Settings
  windowrule = float, class:file-roller
  windowrule = float, class:nautilus
  windowrule = float, class:nemo
  windowrule = float, class:thunar
  windowrule = float, class:Pcmanfm
#   windowrule = float, obs
  windowrule = float, class:wdisplays
  windowrule = float, class:zathura
  windowrule = float, class:*.exe
  windowrule = fullscreen, class:wlogout
  windowrule = float, title:wlogout
  windowrule = fullscreen, title:wlogout
  windowrule = float, class:pavucontrol-qt
  windowrule = float, class:keepassxc
  windowrule = idleinhibit focus, class:mpv
  windowrule = idleinhibit fullscreen, class:firefox
  windowrule = float, title:^(Media viewer)$
  windowrule = float, title:^(Transmission)$
  windowrule = float, title:^(Volume Control)$
  windowrule = float, title:^(Picture-in-Picture)$
  windowrule = float, title:^(Firefox — Sharing Indicator)$
  windowrule = move 0 0, title:^(Firefox — Sharing Indicator)$
  windowrule = size 800 600, title:^(Volume Control)$
  windowrule = move 75 44%, title:^(Volume Control)$
# windowrulev2 = opacity 0.85 0.85,class:^(Alacritty|code-oss)$
# https://github.com/hyprwm/Hyprland/issues/2412
  windowrulev2=nofocus,class:^jetbrains-(?!toolbox),floating:1,title:^win\d+$