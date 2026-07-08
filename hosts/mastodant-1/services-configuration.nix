{ config, lib, pkgs, modulesPath, ... }: {

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  # TODO :: KARIM :: 31/03/2025 ::  Disable GDM to remplace by SDDM
  # Update 2026-01-24 ::
  #    # Old:
  #       services.xserver.desktopManager.gnome.enable
  #       services.xserver.displayManager.gdm.enable
  #    # New:
  #       services.desktopManager.gnome.enable
  #       services.displayManager.gdm.enable
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = false;
  services.displayManager.sddm.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pipewire = let
    pipewireEnabled = true;
  in {
    enable = pipewireEnabled;
    package = pkgs.pipewire;
    alsa = {
      enable = pipewireEnabled;
      support32Bit = pipewireEnabled;
    };
    pulse = {
      enable = pipewireEnabled;
    };
    jack = {
      enable = pipewireEnabled;
    };
    wireplumber = {
      enable = pipewireEnabled;
      package =  pkgs.wireplumber;
    };
  };
  services.pulseaudio.enable = false;



  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}
