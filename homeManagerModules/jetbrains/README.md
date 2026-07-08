# jetbrains

**Status: stub — not yet implemented.**

Placeholder for JetBrains IDE configuration.

## Planned scope

- Configure JetBrains IDEs via the `nix-jetbrains-plugins` flake input
- Manage plugins declaratively
- Apply theming (Stylix or Catppuccin)

## Current state

`home.nix` is empty. The `nix-jetbrains-plugins` flake input is wired into the flake and passed
as `nix-jetbrains-plugins` in `extraSpecialArgs`, so it is available to this module when ready.

`ide.nix`, `plugin.nix`, and `theme.nix` are helper files present in the directory — they
contain the beginnings of a typed configuration structure.

## To implement

1. Choose target IDEs (IntelliJ IDEA, PyCharm, etc.)
2. Declare them using the `nix-jetbrains-plugins` API
3. Add plugin lists to `ide.nix`
4. Wire theming in `theme.nix`
5. Activate in `home.nix`
