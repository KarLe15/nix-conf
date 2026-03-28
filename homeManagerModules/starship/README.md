# starship

Configures the Starship cross-shell prompt.

## What it does

- Enables Starship and delegates base colors to Stylix (`stylix.targets.starship.enable = true`)
- Defines a custom `base16` color palette (colors are injected by Stylix at build time)
- Builds a rich prompt format string with powerline-style segments

## Prompt segments (left to right)

```
[OS icon] [username] [directory] [git branch] [git metrics / status / state] [language versions] [time]
[status] [➜ character]
```

| Segment | Color pair | Content |
|---|---|---|
| OS | `base16` bg | OS icon |
| Username | `base16` bg | Current user |
| Directory | `base08` bg | Truncated path (3 levels, repo root) |
| Git branch | `base09` bg | Branch name with icon |
| Git metrics | `bright-yellow` bg | `+added / -deleted` (disabled by default) |
| Git status | `bright-yellow` bg | Modified / deleted / untracked / conflicted / diverged |
| Git state | `bright-yellow` bg | Rebase / merge / cherry-pick state |
| Languages | `base07` bg | Go / Java / Gradle / Haskell / Julia / Node / Rust / Scala / C / Python |
| Time | `base16` bg | Current time (HH:MM) |
| Command duration | `base08` accent | Duration of last command (shown if > 1500ms) |

## customConfigs dependencies

None — colors come from the Stylix/base16 theming pipeline.

## Notes

- `git_metrics` is disabled by default (set `disabled = false` in the segment config to enable)
- The prompt uses `palette = "base16"` — Stylix fills this palette with the active theme's colors
- Language version segments are shown only when the relevant files are detected in the current directory
