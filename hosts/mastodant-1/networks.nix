{ config, lib, pkgs, modulesPath, ... }: {
  networking.hostName = "karle"; # Define your hostname.
  ## INFO :: The network HostId is mandatory for the ZFS filesystem enable
  ## INFO :: SEE : https://search.nixos.org/options?channel=25.05&show=networking.hostId&from=0&size=50&sort=relevance&type=packages&query=networking.hostId
  ## the value is retrieved from "head -c 8 /etc/machine-id"
  networking.hostId = "60463ab4";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

}