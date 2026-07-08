{ lib, ... }: {
  options.software.wayland-desktop = {
    active = lib.mkOption {
      type        = lib.types.enum [ "standard" ];
      description = "Wayland desktop utilities preset name.";
    };
  };
}
