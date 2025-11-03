{ config, lib, pkgs, modulesPath, ... }: {
  virtualisation = {
    containers.enable = true;
    oci-containers = {
      backend = "podman";
    };
    docker = {
      enable = true;
    };
    podman = let podmanEnabled = false; in {
      enable = podmanEnabled;
      dockerCompat = podmanEnabled;
      defaultNetwork.settings.dns_enabled = podmanEnabled;
    };
  };

  environment.systemPackages = with pkgs; [
    dive
    podman-tui
  ];
}