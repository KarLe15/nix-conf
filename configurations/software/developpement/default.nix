{ lib, config, ... } : {
  imports = [
  ];
  options.software.developpement = {
    active = lib.mkOption {
      type = lib.types.str;
      default = "opensource";
      description = "Active set of developpement software (IDE / API Client / ... )";
    };
  };
}