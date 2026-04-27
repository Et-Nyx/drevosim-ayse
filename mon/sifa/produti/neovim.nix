{ self, inputs, ... }:
{
  flake.nixosModules.neovim =
  { pkgs, ... }:
  let
    misuNeovim = self.packages.${pkgs.stdenv.hostPlatform.system}.misuNeovim;
  in
  {
    programs.neovim = {
      enable = true;
      package = misuNeovim;
    };
  };

  perSystem =
    { pkgs, lib, ... }:
    {
      packages.misuNeovim = inputs.wrapper-modules.wrappers.neovim.wrap {
        inherit pkgs;

        extraPackages = with pkgs; [
          nixd
          rust-analyzer
          lua-language-server
          basedpyright
          nil
          stylua
          alejandra
          cargo
        ];

        hosts.python3.nvim-host.enable = true;

        specs.catppuccin = {
          data = pkgs.vimPlugins.catppuccin-nvim;
          before = [ "INIT_MAIN" ];
          config = ''
            require('catppuccin').setup({
              flavour = 'macchiato',
              integrations = {
                cmp = true,
                gitsigns = true,
                telescope = true,
                neo_tree = true,
                treesitter = true,
                which_key = true,
                lualine = true,
                native_lsp = {
                  enabled = true,
                  inlay_hints = { background = true },
                },
              },
            })
            vim.cmd.colorscheme('catppuccin-macchiato')
          '';
        };

        specs.sleuth = {
          data = pkgs.vimPlugins.vim-sleuth;
        };

        specs.treesitter = {
          data = pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
            nix
            rust
            lua
            python
            bash
            markdown
            markdown_inline
            vim
            vimdoc
            json
            toml
            yaml
            c
            cpp
            html
            css
            javascript
            typescript
          ]);
          config = ''
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
              pattern = "*",
              callback = function()
                vim.wo.foldmethod = "expr"
                vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
              end,
            })
          '';
        };

        specs.which-key = {
          data = pkgs.vimPlugins.which-key-nvim;
          config = ''
            require('which-key').setup({})
          '';
        };

        specs.gitsigns = {
          data = pkgs.vimPlugins.gitsigns-nvim;
          config = ''
            require('gitsigns').setup({
              signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '~' },
                changedelete = { text = '~' },
              },
              on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local function map(mode, l, r, opts)
                  opts = opts or {}
                  opts.buffer = bufnr
                  vim.keymap.set(mode, l, r, opts)
                end
                map('n', '<leader>hs', gs.stage_hunk)
                map('n', '<leader>hr', gs.reset_hunk)
                map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end)
                map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end)
                map('n', '<leader>hS', gs.stage_buffer)
                map('n', '<leader>hR', gs.reset_buffer)
                map('n', '<leader>hp', gs.preview_hunk)
                map('n', '<leader>hb', function() gs.blame_line { full = true } end)
              end,
            })
          '';
        };

        specs.neo-tree = {
          data = pkgs.vimPlugins.neo-tree-nvim;
          config = ''
            require('neo-tree').setup({
              close_if_last_window = true,
              filesystem = {
                follow_current_file = { enabled = true, leave_dirs_open = true },
                hijack_netrw_behavior = 'open_default',
                use_libuv_file_watcher = true,
              },
              window = {
                width = 35,
                auto_expand_width = false,
              },
            })
            vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { noremap = true, silent = true })
            vim.keymap.set('n', '<leader>be', ':Neotree buffers<CR>', { noremap = true, silent = true })
          '';
        };

        specs.telescope = {
          data = pkgs.vimPlugins.telescope-nvim;
          config = ''
            require('telescope').setup({
              defaults = {
                file_ignore_patterns = { 'node_modules', '.git', 'target' },
                layout_strategy = 'flex',
                layout_config = {
                  horizontal = {
                    prompt_position = 'top',
                    preview_width = 0.6,
                  },
                  vertical = {
                    mirror = false,
                  },
                },
                sorting_strategy = 'ascending',
                mappings = {
                  i = {
                    ['<C-j>'] = require('telescope.actions').move_selection_next,
                    ['<C-k>'] = require('telescope.actions').move_selection_previous,
                    ['<C-q>'] = require('telescope.actions').send_to_qflist,
                  },
                },
              },
              pickers = {
                find_files = { hidden = true },
                live_grep = { additional_args = function() return { '--hidden' } end },
              },
            })
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
            vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent files' })
            vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = 'Git commits' })
            vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Git status' })
          '';
        };

        specs.lualine = {
          data = pkgs.vimPlugins.lualine-nvim;
          config = /* lua */ ''
            local sq = "'"
            require('lualine').setup({
              options = {
                theme = 'catppuccin',
                component_separators = { left = sq .. sq, right = sq .. sq },
                section_separators = { left = sq .. sq, right = sq .. sq },
                globalstatus = true,
              },
              sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { { 'filename', path = 1 } },
                lualine_x = { 'encoding', 'fileformat', 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = { 'location' },
              },
            })
          '';
        };

        specs.bufferline = {
          data = pkgs.vimPlugins.bufferline-nvim;
          config = ''
            require('bufferline').setup({
              options = {
                mode = 'buffers',
                diagnostics = 'nvim_lsp',
                show_close_icon = false,
                offsets = {
                  {
                    filetype = 'neo-tree',
                    text = 'File Explorer',
                    highlight = 'Directory',
                    text_align = 'center',
                  },
                },
              },
            })
            vim.keymap.set('n', '<Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true })
            vim.keymap.set('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true })
            vim.keymap.set('n', '<leader>bc', ':BufferLinePickClose<CR>', { noremap = true, silent = true })
          '';
        };

        specs.nvim-cmp = {
          data = pkgs.vimPlugins.nvim-cmp;
          config = ''
            local cmp = require('cmp')
            cmp.setup({
              snippet = {
                expand = function(args)
                  vim.snippet.expand(args.body)
                end,
              },
              window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
              },
              mapping = cmp.mapping.preset.insert({
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-n>'] = cmp.mapping.select_next_item(),
                ['<C-p>'] = cmp.mapping.select_prev_item(),
              }),
              sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'path' },
              }, {
                { name = 'buffer' },
              }),
              formatting = {
                fields = { 'kind', 'abbr', 'menu' },
              },
              experimental = {
                ghost_text = true,
              },
            })
          '';
        };

        specs.lsp-zero = {
          data = pkgs.vimPlugins.lsp-zero-nvim;
          config = ''
            local lsp = require('lsp-zero')
            lsp.preset('recommended')

            lsp.on_attach(function(client, bufnr)
              lsp.default_keymaps({ buffer = bufnr })
              local opts = { buffer = bufnr, noremap = true, silent = true }
              vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
              vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
              vim.keymap.set('n', '<leader>fm', function()
                vim.lsp.buf.format({ async = true })
              end, opts)
            end)

            lsp.ensure_installed({
              'nixd',
              'rust_analyzer',
              'lua_ls',
              'basedpyright',
            })

            lsp.setup()
          '';
        };

        settings.config_directory = lib.generators.mkLuaInline "vim.fn.stdpath('config')";
      };
    };
}
