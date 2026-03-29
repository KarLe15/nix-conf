{ lib, ... }: {
  options.software.shell = {
    active = lib.mkOption {
      type        = lib.types.enum [ "standard" ];
      description = "Shell aliases and environment preset.";
    };
  };
}
