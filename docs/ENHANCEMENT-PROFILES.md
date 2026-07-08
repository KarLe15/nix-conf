# Enhancement Proposal: Profile System & Feature Flags

**Status**: Implemented (all 3 phases, Phase 3 uses Option B)
**Date**: 2026-03-19

---

## Problem Statement

The current system has two pain points:

### 1. Feature flags are hardcoded in the generator

`custom-config-generator.nix` mixes preset resolution with hardcoded module toggle flags:

```nix
modules = {
  eww.enable = false;
  walker.enable = true;
  git-accounts.enable = true;
  waybar.enable = true;
};
```

These flags cannot be changed per-host without modifying the generator itself,
breaking the preset contract. Adding a second host with a different set of
enabled modules requires code changes, not just data changes.

### 2. A host selects 14 independent preset strings

`hosts/mastodant-1/options.nix` currently declares 14 separate `*.active = "..."` assignments.
Adding a second machine duplicates all of them, with high risk of inconsistency.
There is no concept of "this machine is like that profile but with X swapped".

---

## Proposed Solution

### Part 1 — Feature flags as NixOS options

Move module enable flags out of `custom-config-generator.nix` and into a proper
`configurations/software/modules/default.nix` option declaration:

```nix
# configurations/software/modules/default.nix
{ lib, ... }: {
  options.software.modules = {
    waybar.enable       = lib.mkOption { type = lib.types.bool; default = true; };
    eww.enable          = lib.mkOption { type = lib.types.bool; default = false; };
    walker.enable       = lib.mkOption { type = lib.types.bool; default = false; };
    git-accounts.enable = lib.mkOption { type = lib.types.bool; default = true; };
  };
}
```

Then `custom-config-generator.nix` reads them from `cfg.software.modules` just like
it reads preset names from `cfg.software.defaults.active`. Each host can override
individual flags in `options.nix` without touching shared code:

```nix
# hosts/laptop/options.nix
software.modules.waybar.enable = false;   # laptop has a different bar setup
software.modules.eww.enable    = true;
```

---

### Part 2 — Named profiles

Introduce a `configurations/profiles/` directory. A profile is a Nix file that
bundles a complete set of preset selections and feature flag overrides for a
machine archetype:

```
configurations/
└── profiles/
    ├── default.nix          # NixOS option: profile.active :: enum
    └── presets/
        ├── desktop-amd.nix  # AMD gaming/dev desktop
        ├── laptop.nix       # Laptop (lower power, single screen)
        └── server.nix       # Headless server (no Hyprland/Waybar)
```

A profile file looks like:

```nix
# configurations/profiles/presets/desktop-amd.nix
{
  hardware.monitors.active        = "mastodant-3-screens";
  style.themes.active             = "catppuccin-macchiato";
  style.fonts.active              = "mac-like";
  style.cursors.active            = "Bibata";
  style.wallpaper.active          = "standard";
  style.workspaces.active         = "standard-3-screen";
  style.statusbar.active          = "waybar-3-screen";
  software.defaults.active        = "mastodant-1";
  software.shortcuts.active       = "mastodant-1";
  software.git-accounts.active    = "standard";
  software.launchers.active       = "rofi";
  software.powermanagement.active = "systemD";
  software.multimedia.active      = "avizo";
  software.developpement.active   = "opensource";
  software.modules.waybar.enable  = true;
  software.modules.git-accounts.enable = true;
}
```

`flake.nix` applies the profile as a NixOS module, so hosts can select a profile
and only override what differs:

```nix
# hosts/mastodant-1/options.nix  (after the change)
profile.active = "desktop-amd";
# nothing else needed — the profile provides all defaults
```

```nix
# hosts/laptop/options.nix
profile.active = "desktop-amd";      # inherit most settings
style.statusbar.active = "waybar-1-screen";  # override just what differs
software.modules.waybar.enable = false;
```

The profile option in `configurations/profiles/default.nix` applies the selected
profile by importing it as a NixOS module, letting individual option overrides
take precedence via the standard `lib.mkDefault` / `lib.mkForce` priority system:

```nix
# configurations/profiles/default.nix
{ lib, config, ... }:
let
  profile = import ./presets/${config.profile.active}.nix;
in {
  options.profile.active = lib.mkOption {
    type = lib.types.enum [ "desktop-amd" "laptop" "server" ];
    description = "Machine archetype profile. Sets default values for all preset options.";
  };
  # Apply profile values as defaults (overridable per-host)
  config = lib.mapAttrs (k: v: lib.mkDefault v) profile;
}
```

---

### Part 3 — Typed preset contracts (already partially done)

The option description strings (updated in this PR with `lib.types.enum` and
type pseudocode) serve as informal contracts. To harden this further:

**Option A — Assertion-based validation** (low effort)

Add `lib.assertMsg` checks in `custom-config-generator.nix` that verify the
resolved preset attrset has the required keys:

```nix
monitors =
  let m = import ./configurations/hardware/monitors/presets/${hw.monitors.active}.nix;
  in assert lib.assertMsg (m ? apply) "monitors preset must export 'apply'";
     assert lib.assertMsg (m ? autostart) "monitors preset must export 'autostart'";
     m;
```

**Option B — Submodule types** (higher effort, stronger guarantees)

Define the preset output as a `lib.types.submodule` and validate it through the
NixOS module system. The `git-accounts/options.nix` already does this for account
structures — the same pattern can be applied to preset outputs.

---

## Migration Path

1. **Phase 1** (no breaking changes): Add `configurations/software/modules/default.nix`
   with the feature flag options. Update `custom-config-generator.nix` to read from
   `cfg.software.modules` instead of the hardcoded attrset. Update `hosts/mastodant-1/options.nix`
   to explicitly set each flag.

2. **Phase 2** (no breaking changes): Add `configurations/profiles/`. Create the
   `desktop-amd` profile matching current `options.nix` exactly. Switch
   `hosts/mastodant-1/options.nix` to `profile.active = "desktop-amd"`.

3. **Phase 3** (additive): Add new profiles as new hosts are introduced.
   Add assertion-based preset validation in `custom-config-generator.nix`.

---

## Summary of Benefits

| Current | After |
|---|---|
| 14 independent preset strings per host | 1 profile selection per host, override only what differs |
| Feature flags hardcoded in generator | Feature flags as NixOS options, overridable per host |
| `lib.types.str` for preset names | `lib.types.enum` + contract docstring (already done) |
| No compile-time preset validation | Optional: assertions or submodule types |
| Duplicated defaults across machines | Profile provides shared defaults, host overrides are minimal |
