{ config, lib, pkgs, modulesPath, ... }: {
  users.users= {
    karim = {
      isNormalUser = true;
      description = "Karim";
      extraGroups = [ "networkmanager" "wheel" "users" "docker"];
      shell = pkgs.fish;
    };
  };
  ## Add Karim as trusted user for cachix usage, 
  ## Required for devenv to work properly
  nix.settings.trusted-users = [ "root" "karim" ];
}