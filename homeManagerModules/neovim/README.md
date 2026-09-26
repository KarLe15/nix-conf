# neovim

Configures Neovim declaratively through [nvf](https://github.com/NotAShelf/nvf).

## What it does

- Enables `programs.nvf` and sets it as the default editor (`EDITOR=nvim`)
- Reproduces the feature set of [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
  using nvf's Nix modules instead of Lua plugin specs
- Installs language servers, formatters and linters from nixpkgs — **no Mason**
- Delegates theming entirely to Stylix (`stylix.targets.nvf`)

## Theming

This module deliberately does **not** set `vim.theme`. Stylix auto-enables its
`nvf` target (`stylix.autoEnable = true` in `homeManagerModules/default.nix`) and
writes `vim.theme.{enable,name,base16-colors}` plus the lualine theme from the
active base16 palette. Setting a colourscheme here would conflict with it.

## Plugin mapping (kickstart.nvim → nvf)

| kickstart.nvim | nvf option |
|---|---|
| `lazy.nvim` | built in (`vim.lazy`) |
| `which-key.nvim` | `vim.binds.whichKey.enable` |
| `telescope.nvim` | `vim.telescope.enable` |
| `nvim-lspconfig` + `mason.nvim` | `vim.lsp.enable` + `vim.languages.<lang>.lsp` |
| `conform.nvim` | `vim.formatter.conform-nvim.enable` |
| `nvim-lint` | `vim.diagnostics.nvim-lint.enable` |
| `blink.cmp` | `vim.autocomplete.blink-cmp.enable` |
| `LuaSnip` | `vim.snippets.luasnip.enable` |
| `nvim-treesitter` (+ textobjects) | `vim.treesitter.{enable,context,textobjects}` |
| `gitsigns.nvim` | `vim.git.gitsigns.enable` |
| `todo-comments.nvim` | `vim.notes.todo-comments.enable` |
| `mini.ai`, `mini.surround` | `vim.mini.{ai,surround}.enable` |
| `mini.statusline` | `vim.statusline.lualine.enable` (Stylix themes lualine) |
| `nvim-autopairs` | `vim.autopairs.nvim-autopairs.enable` |
| `indent-blankline.nvim` | `vim.visuals.indent-blankline.enable` |
| `tokyonight.nvim` | Stylix (see above) |
| `lazydev.nvim` | covered by `vim.languages.lua` |

## Settings applied

| Setting | Value | Reason |
|---|---|---|
| `mapleader` / `maplocalleader` | `" "` | kickstart default |
| `lineNumberMode` | `"relNumber"` | absolute + relative line numbers |
| `searchCase` | `"smart"` | `ignorecase` + `smartcase` |
| `undoFile.enable` | `true` | persistent undo history |
| `preventJunkFiles` | `true` | no swap/backup files next to sources |
| `clipboard.registers` | `"unnamedplus"` | share the system clipboard (via `wl-copy`) |
| `lsp.formatOnSave` | `false` | explicit save discipline, same as the zed module |
| `lsp.inlayHints.enable` | `true` | inline type/parameter hints |
| `showmode` | `false` | lualine already renders the mode |

## Languages enabled

`nix` (nixd), `lua`, `bash`, `qml`, `markdown`, `json`, `yaml`, `toml`, `rust`,
`typescript`, `python`.

`qml` is enabled for the `homeManagerModules/quickshell` sources.

## customConfigs dependencies

- `softwareConfigs.modules.neovim.enable` — the feature flag

## Notes

- The nvf Home Manager module is imported globally in `flake.nix`
  (`nvf.homeManagerModules.default`); this module only configures it
- Bare `neovim` was removed from the global package list in
  `homeManagerModules/default.nix` — nvf installs its own wrapped `nvim`.
  `vim` and `helix` are still installed as fallbacks
- `software.defaults` still declares `terminal-editor.package = pkgs.neovim`.
  Nothing installs that attribute (only `.command` is consumed), so it is inert
  metadata and does not shadow the nvf wrapper
- Not enabled, kept as easy additions: `vim.filetree.neo-tree` and
  `vim.debugger.nvim-dap` (both shipped commented-out in kickstart too)
