{ lib, ... } : {
  imports = [
    ./defaults
    ./developpement
    ./git-accounts
    ./shortcuts
    ./launchers
    ./powermanagement
    ./multimedia
  ];
}