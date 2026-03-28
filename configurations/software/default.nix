{ lib, ... } : {
  imports = [
    ./modules
    ./defaults
    ./developpement
    ./git-accounts
    ./shortcuts
    ./launchers
    ./powermanagement
    ./multimedia
  ];
}