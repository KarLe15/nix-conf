{ pkgs, lib, customConfigs, ... }:
let
  cfg = customConfigs.softwareConfigs.modules.neovim;
in {
  config = lib.mkIf cfg.enable {
    ## INFO :: The colourscheme is NOT set here. `stylix.targets.nvf` is picked up
    ## automatically (stylix.autoEnable = true) and drives `vim.theme.*` plus the
    ## lualine theme from the base16 palette. Setting vim.theme here would fight it.
    programs.nvf = {
      enable        = true;
      defaultEditor = true;

      settings.vim = {
        viAlias  = false;
        vimAlias = true;

        ## ── Core behaviour (kickstart.nvim's `vim.opt` block) ──────────────
        globals = {
          mapleader      = " ";
          maplocalleader = " ";
        };

        lineNumberMode   = "relNumber";   # number + relativenumber
        preventJunkFiles = true;          # no swapfile / backupfile
        searchCase       = "smart";
        undoFile.enable  = true;

        options = {
          mouse       = "a";
          showmode    = false;            # lualine already shows the mode
          breakindent = true;
          signcolumn  = "yes";
          updatetime  = 250;
          timeoutlen  = 300;
          splitright  = true;
          splitbelow  = true;
          list        = true;
          listchars   = "tab:» ,trail:·,nbsp:␣";
          inccommand  = "split";
          cursorline  = true;
          scrolloff   = 10;
          confirm     = true;
        };

        clipboard = {
          enable                   = true;
          registers                = "unnamedplus";
          providers.wl-copy.enable = true;   # Wayland session
        };

        ## ── Keymaps (kickstart.nvim's handful) ────────────────────────────
        keymaps = [
          { mode = "n"; key = "<Esc>";      action = "<cmd>nohlsearch<CR>"; desc = "Clear search highlight"; }
          { mode = "t"; key = "<Esc><Esc>"; action = "<C-\\><C-n>";         desc = "Exit terminal mode"; }
          { mode = "n"; key = "<C-h>"; action = "<C-w><C-h>"; desc = "Focus window left"; }
          { mode = "n"; key = "<C-j>"; action = "<C-w><C-j>"; desc = "Focus window below"; }
          { mode = "n"; key = "<C-k>"; action = "<C-w><C-k>"; desc = "Focus window above"; }
          { mode = "n"; key = "<C-l>"; action = "<C-w><C-l>"; desc = "Focus window right"; }
        ];

        ## ── Plugins (kickstart.nvim's set, mapped onto nvf modules) ───────
        binds.whichKey.enable            = true;
        telescope.enable                 = true;
        git.gitsigns.enable              = true;
        notes.todo-comments.enable       = true;
        autopairs.nvim-autopairs.enable  = true;
        snippets.luasnip.enable          = true;
        autocomplete.blink-cmp.enable    = true;
        statusline.lualine.enable        = true;
        visuals.indent-blankline.enable  = true;
        visuals.nvim-web-devicons.enable = true;

        mini = {
          ai.enable       = true;
          surround.enable = true;
        };

        treesitter = {
          enable             = true;
          context.enable     = true;
          textobjects.enable = true;
        };

        ## INFO :: No Mason — language servers come from nixpkgs via vim.languages.*
        lsp = {
          enable            = true;
          formatOnSave      = false;   # mirrors the zed module: explicit save discipline
          inlayHints.enable = true;
          trouble.enable    = true;
        };

        formatter.conform-nvim.enable = true;
        diagnostics.nvim-lint.enable  = true;

        ## ── Languages :: LSP + treesitter + formatter, all from nixpkgs ───
        languages = {
          enableTreesitter       = true;
          enableFormat           = true;
          enableExtraDiagnostics = true;

          nix = {
            enable      = true;
            lsp.servers = [ "nixd" ];   # matches the nixd already in home.packages
          };
          lua.enable        = true;
          bash.enable       = true;
          qml.enable        = true;     # for the quickshell modules
          markdown.enable   = true;
          json.enable       = true;
          yaml.enable       = true;
          toml.enable       = true;
          rust.enable       = true;
          typescript.enable = true;
          python.enable     = true;
        };
      };
    };
  };
}
