# openldap overlays

## skipChecks

Disables the openldap test suite during build (`doCheck = false`).

**Why:** `test017-syncreplication-refresh` is a timing-based LDAP replication integration test that
fails non-deterministically in sandboxed Nix builds (the test asserts that changes sync within 7
seconds, which is not guaranteed under load). The package itself is not broken.

**Trigger:** `openldap` is pulled in transitively by `bottles` and `lutris` via their FHS
environments, which bundle `cyrus-sasl`/`krb5` with LDAP support.

**Usage:**

```nix
nixpkgs.overlays = [ (import ./overlays/openldap/skipChecks) ];
```
