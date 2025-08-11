{ config, lib, pkgs, modulesPath, ... }: {
  environment.systemPackages = with pkgs; [
    ## === Core Gaming Tools ===
    lutris                    # Game launcher/manager
    bottles                   # Modern Wine prefix manager
    heroic                    # Epic Games & GOG launcher
    legendary-gl              # Epic Games CLI

    ## === Wine Ecosystem ===
    wineWowPackages.staging   # Wine staging with 32/64-bit
    winetricks               # Wine configuration utility
    protontricks             # Proton prefix management

    ## === Performance & Monitoring ===
    mangohud                 # FPS/performance overlay
    goverlay                 # MangoHud GUI configuration
    gamemode                 # Automatic performance optimization
    gamescope                # Wayland game compositor

    ## === GPU Tools ===
    radeontop                # AMD GPU monitoring
    gpu-viewer               # GPU information viewer
    amdgpu_top               # Better AMD GPU monitor
    
    # Vulkan tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers

    ## === Emulation ===
    retroarch                # Multi-emulator frontend
    pcsx2                    # PS2 emulator
    rpcs3                    # PS3 emulator
    dolphin-emu              # GameCube/Wii emulator
    mupen64plus              # N64 emulator

    ## === Utilities ===
    steam-run               # Run non-NixOS binaries
    appimage-run            # Run AppImages
    piper                   # Gaming mouse configuration
    solaar                  # Logitech device manager

    ## === Additional Launchers ===
    prismlauncher           # Minecraft launcher
    atlauncher              # Modded Minecraft launcher

  ];
  
  # Udev rules for controllers and gaming peripherals
  services.udev.packages = with pkgs; [
    game-devices-udev-rules  # Controller support
  ];

  # Enable Xbox controller support
  hardware.xone.enable = true;           # Xbox One/Series controllers
  hardware.xpadneo.enable = true;        # Xbox Wireless controller

  # Fonts for games (some games need Windows fonts)
  fonts.packages = with pkgs; [
    corefonts              # Microsoft fonts
    vistafonts             # Vista fonts
    liberation_ttf         # Liberation fonts
  ];

  # GameMode for performance optimization (Temporary when the game run for dynamic optimization setup)
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 0;
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };
  
  # Steam
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin  # Community Proton with extra fixes
    ];
  };
}