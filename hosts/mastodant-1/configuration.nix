{ config, pkgs, inputs, lib, ... }: {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./kernel.nix
      ./custom-hardware.nix
      ./services-configuration.nix
      ./locales.nix
      ./networks.nix
      ./security.nix
      ./options.nix
      ./programs.nix
      ./gaming.nix
      ./users.nix
      ./filesystems.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = {
    btrfs = true;
    zfs = true;
    xfs = true;
    ext4 = true;
  };
  services.zfs.autoScrub.enable = true;

  

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List services that you want to enable:

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  ## ==========================================================================================================
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
