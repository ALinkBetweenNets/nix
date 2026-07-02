{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib;
{
  # programs.neovim = {
  #   enable = true;
  #   coc.enable = true;
  #   plugins = with pkgs.vimPlugins; [ yankring vim-nix ];
  # };
  config = {
    programs.helix = {
      enable = true;
      settings = {
        theme = "base16_transparent";
        editor = {
          line-number = "relative";
          cursorline = true;
          color-modes = true;
          lsp = {
            display-inlay-hints = true;
            display-messages = true;
          };
          soft-wrap.enable = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
        };
      };
      languages = {
        language-server.tinymist = {
          command = "tinymist";
          environment.RUST_LOG = "tinymist=debug,typst_preview=debug";
          config = {
            formatterMode = "typstyle";
            exportPdf = "onSave";
            semanticTokens = "enable";
            preview.background.enable = true;
            # preview.background.args = [
            # "--data-plane-host=127.0.0.1:0"
            # "--invert-colors=never"
            # "--open"
            # ];
          };
        };
        language = [
          {
            name = "nix";
            auto-format = true;
            formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          }
          {
            name = "typst";
            scope = "source.typst";
            injection-regex = "typst";
            file-types = [ "typ" ];
            comment-token = "//";
            language-servers = [ "tinymist" ];
            auto-format = true; # <- format on save (delegated to tinymist/typstyle)
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            text-width = 100;
            rulers = [ 100 ];
            soft-wrap.wrap-at-text-width = true;
          }
        ];
      };
    };
    programs.nvf = {
      enable = true;
      # your settings need to go into the settings attribute set
      # most settings are documented in the appendix
      settings.vim = {
        options = {
          tabstop = 2;
          shiftwidth = 2;
        };
        syntaxHighlighting = true;
        spellcheck.enable = true;
        viAlias = false;
        vimAlias = true;
        lsp = {
          enable = true;
          formatOnSave = false;
          lightbulb.enable = true;
          # lsplines.enable = true;
          lspsaga.enable = true;
          lspSignature.enable = false; # For blink
          lspkind.enable = true;
          nvim-docs-view.enable = true;
          otter-nvim.enable = true;
          trouble.enable = true;
        };
        autocomplete = {
          blink-cmp = {
            enable = true;
            friendly-snippets.enable = true;
            setupOpts.signature.enabled = true;
            mappings.confirm = "<C-Tab>";
          };
        };
        autopairs.nvim-autopairs.enable = false; # Creates closing brackets when you enter opening bracket
        debugger.nvim-dap = {
          enable = true;
          ui.enable = true;
        };
        lazy.enable = true; # Lazy Plugin loading
        diagnostics.nvim-lint.enable = true;
        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;
          rust.extensions.crates-nvim.enable = true;
          bash.enable = true;
          go.enable = true;
          html.enable = true;
          php.enable = true;
          python = {
            lsp.servers = [ "pyright" ];
            enable = true;
          };
          sql.enable = true;
          typescript.enable = true;
          nix = {
            enable = true;
            format.type = [ "nixfmt" ];
          };
          markdown.enable = true;
          # markdown.extensions.render-markdown-nvim.enable = true; # does not display partial todo boxes
          markdown.extensions.markview-nvim.enable = true;
          css.enable = true;
          typst.enable = true;
          clang = {
            enable = true;
            lsp.servers = [ "clangd" ];
          };
        };
        formatter.conform-nvim.enable = true;
        visuals = {
          cellular-automaton.enable = true; # fml
          cinnamon-nvim = {
            enable = false; # smooth scroll
            setupOpts.keymaps.basic = true;
            setupOpts.keymaps.extra = true;
          };
          fidget-nvim.enable = false; # notifications/ ui bottom right
          highlight-undo.enable = true;
          indent-blankline.enable = true;
          nvim-cursorline = {
            enable = true;
            setupOpts.line_timeout = 0;
          };
          nvim-scrollbar.enable = true;
          nvim-web-devicons.enable = true;
          rainbow-delimiters.enable = true;
          tiny-devicons-auto-colors.enable = true;
        };
        statusline = {
          lualine = {
            enable = true;
            theme = "auto";
          };
        };
        theme = {
          enable = true;
          #name = "darker";
          style = "night";
          name = "tokyonight";
          transparent = true;
        };
        filetree = {
          neo-tree = {
            enable = false;
            setupOpts = {
              close_if_last_window = true;
              enable_diagnostics = true;
              enable_git_status = true;
              enable_modified_markers = true;
              open_files_in_last_window = true;
              git_async_status.enable = true;
              enable_cursor_hijack = true;
              filesystem.hijack_netrw_behavior = "disabled";
            };
          };
        };
        tabline = {
          nvimBufferline.enable = true;
        };
        treesitter = {
          enable = true;
          highlight.enable = true;
          context.enable = true;
        };
        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };
        telescope.enable = true;
        git = {
          enable = true;
          gitsigns = {
            enable = true;
            codeActions.enable = true;
          }; # throws an annoying debug message
        };
        minimap = {
          # minimap-vim.enable = true;
          codewindow.enable = false; # lighter, faster, and uses lua for configuration
        };
        dashboard = {
          # dashboard-nvim.enable = true;
          alpha.enable = true;
        };
        searchCase = "ignore";
        notify = {
          nvim-notify.enable = true;
        };
        projects = {
          project-nvim.enable = true;
        };
        utility = {
          yazi-nvim.enable = true;
          ccc.enable = true;
          # vim-wakatime.enable = true;
          icon-picker.enable = true;
          surround.enable = true;
          diffview-nvim.enable = true;
          motion = {
            hop.enable = true;
            leap.enable = true;
            precognition.enable = false;
          };
          images = {
            image-nvim.enable = false;
            image-nvim.setupOpts.backend = "kitty";
          }; # Does not work in Konsole
        };
        notes = {
          #obsidian.enable =
          #  true; # FIXME: neovim fails to build if obsidian is enabled
          #obsidian.setupOpts.workspaces = [
          #  {
          #    name = "obsidian";
          #    path = "/home/l/obsidian";
          #  }
          #];

          orgmode.enable = false;
          # mind-nvim.enable = true;
          todo-comments.enable = true;
        };
        terminal = {
          toggleterm = {
            enable = true;
            mappings.open = "<c-t>";
            setupOpts.winbar.enable = true;
            lazygit.enable = true;
          };
        };
        clipboard = {
          enable = true;
          providers.wl-copy.enable = true;
        };
        utility.outline.aerial-nvim.enable = true;
        ui = {
          borders = {
            enable = true;
            plugins = {
              fastaction = {
                enable = true;
                style = "rounded";
              };
              lsp-signature.enable = false;
              nvim-cmp.enable = true;
            };
          };
          noice.enable = false;
          colorizer.enable = true;
          modes-nvim.enable = false; # the theme looks terrible with catppuccin
          illuminate.enable = true;
          breadcrumbs = {
            enable = false;
            navbuddy.enable = true;
          };
          smartcolumn = {
            enable = false;
            setupOpts.custom_colorcolumn = {
              # this is a freeform module, it's `buftype = int;` for configuring column position
              nix = "110";
              ruby = "120";
              java = "130";
              go = [
                "90"
                "130"
              ];
            };
          };
          fastaction.enable = true;
        };
        keymaps = [
          {
            key = "<leader>e";
            mode = "n";
            desc = "Toogle Neotree";
            action = "<cmd>Neotree toggle reveal<cr>";
          }
        ];
        assistant = {
          chatgpt.enable = false;
          copilot = {
            enable = false;
            cmp.enable = false;
          };
        };
        session.nvim-session-manager.enable = true;
        gestures.gesture-nvim.enable = true; # left mouse button + drag
        comments.comment-nvim.enable = true; # gcc, gbc
        presence.neocord.enable = false;
      };
    };
  };
}
