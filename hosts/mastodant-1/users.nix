{ config, lib, pkgs, modulesPath, ... }: {
  users.users= {
    karim = {
      isNormalUser = true;
      description = "Karim";
      extraGroups = [ "networkmanager" "wheel" "users" ];
      shell = pkgs.fish;
    };
  };
}