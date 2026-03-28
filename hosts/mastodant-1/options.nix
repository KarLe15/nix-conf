{ lib, ... }: {
  ## Select machine archetype profile.
  ## All preset selectors and feature flags are provided by the profile.
  ## Override individual options below only when this machine differs.
  profile.active = "desktop-amd";

  ## ===============================<   stylix   >==========================================
  ## Machine-specific override — qtct is required for proper Qt theming on this host.
  stylix.targets.qt.platform = lib.mkForce "qtct";
}