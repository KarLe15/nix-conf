{ config, lib, pkgs, modulesPath, ... }: {
  environment.systemPackages = with pkgs; [
    ## === Core Gaming Tools ===
    lutris                    # Game launcher/manager
    bottles                   # Modern Wine prefix manager
    heroic                    # Epic Games & GOG launcher
    legendary-gl              # Epic Games CLI

    ## === Wine Ecosystem ===
    wineWow64Packages.staging   # Wine staging with 32/64-bit
    winetricks               # Wine configuration utility
    protontricks             # Proton prefix management
    protonup-qt
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
    # nexusmods-app-unfree    # Mod Manager (mainly for skyrim)
    ## === Additional Launchers ===
    prismlauncher           # Minecraft launcher
    atlauncher              # Modded Minecraft launcher


    ## 2026-01-27 :: Steam wrapper for disabling Steam SDL controller
    # Issue on Nixos Steam for SDL
    (pkgs.writeShellScriptBin "steam" ''
      export SDL_JOYSTICK_HIDAPI=0
      exec ${pkgs.steam}/bin/steam "$@"
    '')
  ];

  # nixpkgs.config.permittedInsecurePackages = [
  #   "nexusmods-app-unfree-0.21.1"
  # ];
  # Udev rules for controllers and gaming peripherals
  services.udev.packages = with pkgs; [
    game-devices-udev-rules  # Controller support
    steam-devices-udev-rules             # Steam udev rules
  ];
  hardware.steam-hardware.enable = true;

  # Enable Xbox controller support
  hardware.xone.enable = true;           # Xbox One/Series controllers
  hardware.xpadneo.enable = true;        # Xbox Wireless controller

  # Fonts for games (some games need Windows fonts)
  fonts.packages = with pkgs; [
    corefonts              # Microsoft fonts
    ## Update 2026-01-24 :: vistafonts -> vista-fonts
    vista-fonts             # Vista fonts
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
    package = pkgs.steam.override {
      extraPkgs = (pkgs: with pkgs; [
        gamemode
        # Add other required packages here (e.g., python3 for some games)
      ]);
    };
  };
}
