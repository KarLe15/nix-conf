# git-accounts

Configures multi-account Git and SSH from the `git-accounts` preset.

## What it does

- Conditionally enabled via `customConfigs.softwareConfigs.modules.git-accounts.enable`
- Generates `~/.ssh/config` match blocks for each git account (alias → origin + identity file)
- Adds a global `Host *` block with keepalive settings (`ServerAliveInterval 60`, `ServerAliveCountMax 3`)
- Configures global git settings: `pull.rebase`, `push.autoSetupRemote`, fsck hardening, default branch `main`

## customConfigs dependencies

| Preset | Field accessed |
|---|---|
| `softwareConfigs.modules.git-accounts.enable` | boolean feature flag |
| `softwareConfigs.defaults` | `.apply { inherit pkgs; }` → `defaultEditor` (git core.editor) |
| `softwareConfigs.git-accounts` | `.apply { inherit pkgs default-programs; }` → account list + defaultEditor |

## Git account structure (from preset)

```nix
{
  username   = string;   # Git username
  email      = string;   # Commit email
  key        = path;     # Path to SSH private key (managed by ragenix)
  dns-alias  = string;   # SSH Host alias, e.g. "github-perso"
  dns-origin = string;   # Real hostname, e.g. "github.com"
}
```

Use the alias as the hostname in remote URLs:
```
git remote add origin git@github-perso:KarLe15/myrepo.git
```

## options.nix

`options.nix` declares `programs.git-multi-account` NixOS options (a submodule type) for the account structure. These are not currently wired to the Home Manager config — the preset data is used directly instead.

## Notes

- SSH keys are encrypted with ragenix and stored in `secrets_store/`
- The `generateSSHBlockAsString` function is kept as a reference but the typesafe `generateSSHBlock` (producing an attrset) is used in production
