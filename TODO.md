## Storage solution
### Drive 1 : 
- For a 1TB hard drive SSD for pgp-encrypted archived for important data 
strategy: 
- - use LVM to create a virtial storage (1 HD now but with more hardrives later)
- - create an XFS FS in the full LVM
- - Do this all manually then adapt it to the NixOS config
- - Next step is to add it as a disko module (More advanced and better)

commands : 
```shell
sudo pvcreate /dev/sdc
sudo vgcreate archives-vg /dev/sdc
sudo lvcreate -l 100%FREE -n archives-lv archives-vg
sudo mkfs.xfs /dev/archives-vg/archives-lv
```
### Drive 2 : 
- For a mirroring 2 drives of 500GB SSD used for important files / PDF / Images 
strategy:
- - use ZFS mirroring 
- - Do this all manually then adapt it to the NixOS config
- - Next step is to add it as a disko module (More advanced and better)
### Drive 3 : 
- For code/repo data + XFS large files (Movies / media)
strategy: 
- - Create 2 partitions 1 for Media the other for code / repo
- - 1 partition with btrfs for repos + 1 subvolume per repo
- - 1 partition with XFS for media data
- - Create a tool to manage btrfs repos (Copy / store / describe)
- - Create an MCP server with the tool to later build a IA tool to generate tests for it  

## DONE
- Global Font Setting
- SystemD startup 
- - UWSM
- - https://wiki.archlinux.org/title/Universal_Wayland_Session_Manager
- - https://wiki.hyprland.org/Useful-Utilities/Systemd-start/
- - https://github.com/abenz1267/walker/issues/279
- extra XDG Portals
- - https://wiki.hyprland.org/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
- Pipewire 
- - https://github.com/wwmm/easyeffects
- HyprIdle / Hyprlock / Hyprpaper / >WLeave|Wlogout
- - HyprPaper (DONE) : Wallpaper engine (DONE)
- - HyprLock (DONE) : the lock screen displayed (DONE Basics) 
- - WLeave (DONE) : A logout screen with lock/hibernate/shutdown/reboot 
- - - (DONE) (Done with issue on icons when run via hyprland) // hyprctl dispatch exec "GDK_PIXBUF_MODULE_FILE=/nix/store/nnbp7fjmka7fijjsn35pfflh4qb4303r-librsvg-2.59.2/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache uwsm app -- wleave"
- - - (DONE) Issue with Suspend and Hiberbate (It load back immediatly) (Corrected with kernel params + USB)
- - - (DONE) https://github.com/AMNatty/wleave/
- - HyprIdle (DONE) : Idle daemon that hibernate/sleeps the computer after X seconds (To D)
- Notifications
- OSD 
- - Choice Avizo with custom shortcuts
- - https://github.com/System64fumo/syshud
- - https://github.com/heyjuvi/avizo
- - https://github.com/ErikReider/SwayOSD
- Secrets Management Used ragenix (Done with backup)
- - https://github.com/yaxitech/ragenix
- - https://github.com/alyraffauf/secrets
- Authentication Agent 
- - https://wiki.hyprland.org/Hypr-Ecosystem/hyprpolkitagent/
- Git config
- Status bar (Choice Waybar)
- - Start configuration done
- - https://github.com/jasper-clarke/hypr-ws-switcher
- - https://github.com/KZDKM/Hyprspace          (Cool Feature but not what I want)
- - https://github.com/elkowar/eww              (Too complexe to start)
- - https://github.com/JakeStanger/ironbar      (Solution 1)  (Not taken due to missing exemples)
- - https://github.com/Alexays/Waybar           (Solution 2)
- - https://github.com/vars1ty/HybridBar        (Archived)
- - https://github.com/LBCrion/sfwbar           (S* expression defined status bar)
- Screenshots 
- - https://github.com/flameshot-org/flameshot
- - https://github.com/gabm/satty
- - nix-shell -p obs-studio grim slurp satty
- Setup WIndow Rule and Workspace rule
- - Setup navigation shortcuts with vim bindings
- Clipboard Manager
- - https://github.com/sentriz/cliphist
## Missing parts
- Rofi
- - Customize the rofi config to be more nixos
- Clean TODOs
- Setup Shell (nushell / fish)
- CLI utilities 
- - nushell
- - bat
- - zellij
- - lsd / eza
- - zoxide
- - fd-find
- - kondo
- - tokei
- - yazi
- - fzf
- - ripgrep
- - fd
- - bat
- - eza
- - starship
- - delta
- Some Aliases : 
```
# ls Command
alias ls='eza -lhF --icons -RT -L1 --hyperlink --group-directories-first --time-style="+%Y-%m-%d %H:%M" -m --git -rs size'
# OLD with color scale
# alias ls='eza -lhF --color-scale --icons -RT -L1 --hyperlink --group-directories-first --time-style="+%Y-%m-%d %H:%M" -Um --git -rs size'
alias ll='ls -a'

alias gitui='gitui -t macchiato.ron'

# Cat command
alias cat='bat'
alias cata='cat -A'

# find command
# this alias is unset cause of the fd api is not compatible with find api
# Need find api for setup of sdkman
# alias find='fd'


# grep command
alias grep='rg'
```
- Applications : 
- - Slack 
- - Discord
- - Idea
- - Bitwarden
- - VLC
- - Spotify
- Browser configs 
- - brave
- - firefox
- - zen browser
- Docker / Libvirt / kvm / Qemu
- SDDM setup
- Nix LSP
- Gaming (Steam / Drivers / Emulation)
- - https://github.com/erffy/zig-waybar-contrib?tab=readme-ov-file
- - https://emudeck.github.io/
- - https://github.com/alyraffauf/bazznix/blob/master/nixosModules/apps/podman/default.nix
- - https://github.com/oxalica/nil
- Screen sharing
- - https://gist.github.com/brunoanc/2dea6ddf6974ba4e5d26c3139ffb7580
- Cachix https://wiki.hyprland.org/Nix/Cachix/
- HyprIdle during games
- - https://www.reddit.com/r/hyprland/comments/1enu1lc/hypridle_ignoring_mpv/
- Game mode for game optimization
- - https://github.com/Alexays/Waybar/wiki/Module:-Gamemode
- Bluetooth
- - Add bluetooth control
- - Add controil in waybar
- - https://github.com/Alexays/Waybar/wiki/Module:-Bluetooth
- Notifications :
- - Style notifications for spacing 
- - Add sound for all notifications
- - Add special sound for Discord / Slack notifications
- See around 
- - https://github.com/JaKooLit/NixOS-Hyprland/
- - https://github.com/richen604/hydenix
- - https://gitlab.com/Zaney/zaneyos/
## Nice to have
- Git scripts to clone/Create repository for specific account
- Git script to switch repos from accounts (.git manipulation) 
- Upscaler : Image scaller 
- Bottles : Game launcher (Wine apps)
- ADWSteamGTK : Apply Adwaita theme to steam app
- https://github.com/nix-community/disko
- Plug/unplug screen
- - https://git.sr.ht/~emersion/kanshi
- - https://github.com/coffebar/hyprland-monitor-attached
- https://github.com/Zerodya/hyprfreeze
- https://github.com/ckaznable/hyprnavi?tab=readme-ov-file
- https://github.com/alyraffauf/wallpapers

https://github.com/LuckyTurtleDev/crab-hole
https://www.kismetwireless.net/docs/readme/intro/passive_capture/

## About / Refs
- https://github.com/nwg-piotr/nwg-shell
- Awesome Hyprland
- - https://github.com/hyprland-community/awesome-hyprland
- Nix Config ideas to see
- - https://github.com/alyraffauf/nixcfg
- - https://github.com/Oughie/nixos-config
- - https://github.com/mylinuxforwork/dotfiles
- - https://github.com/fufexan/dotfiles
- - https://github.com/notusknot/dotfiles-nix
- - https://github.com/coffebar/dotfiles