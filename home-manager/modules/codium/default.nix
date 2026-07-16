{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.link.code;
in
{
  options.link.code.enable = mkEnableOption "activate vscodium";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gdb
      nil
      clang
      gnumake
      nixd
      nixfmt
      vscode-langservers-extracted
    ];
    programs.vscodium = {
      enable = true;
      # package = pkgs.vscodium;
      profiles.default = {
        userMcp = {
          "servers" = {
            "Github" = {
              "url" = "https://api.githubcopilot.com/mcp/";
            };
          };
        };
        # package = pkgs.vscode.fhsWithPackages (ps: with ps; [ rustup zlib openssl.dev pkg-config  ]);
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = true;
        extensions =
          with pkgs.vscode-extensions;
          [
            # continue.continue # ollama
            # bradlc.vscode-tailwindcss
            # christian-kohler.npm-intellisense
            # dbaeumer.vscode-eslint
            # dracula-theme.theme-dracula
            # firefox-devtools.vscode-firefox-debug
            # gitlab.gitlab-workflow
            # usernamehw.errorlens
            # yoavbls.pretty-ts-errors
            #b4dm4n.vscode-nixpkgs-fmt
            #vscodevim.vim
            anthropic.claude-code
            arrterian.nix-env-selector
            christian-kohler.path-intellisense
            eamodio.gitlens
            esbenp.prettier-vscode
            github.copilot
            github.copilot-chat
            github.vscode-github-actions
            github.vscode-pull-request-github
            gruntfuggly.todo-tree
            jnoortheen.nix-ide
            mkhl.direnv
            ms-vscode-remote.remote-ssh
            myriad-dreamin.tinymist
            myriad-dreamin.tinymist # typst
            redhat.vscode-xml
            redhat.vscode-yaml
            streetsidesoftware.code-spell-checker
            streetsidesoftware.code-spell-checker-german
            vadimcn.vscode-lldb
            yzhang.markdown-all-in-one
            # pokey.talon
            # pokey.cursorless
          ]
          # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          #   {
          #     name = "vscode-pets";
          #     publisher = "tonybaloney";
          #     version = "1.25.1";
          #     sha256 = "6acdded8bcca052b221acfd4188674e97a9b2e1dfb8ab0d4682cec96a2131094";
          #   }
          # ]
          ;
        userSettings = {
          "[typescriptreact]" = {
            "editor.defaultFormatter" = "vscode.typescript-language-features";
          };
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";
          # "nix.serverPath" = "nixd";
          "nix.serverSettings" = {
            "nil" = {
              "diagnostics" = {
                "ignored" = [
                  "unused_binding"
                  "unused_with"
                ];
              };
              "formatting" = {
                "command" = [ "nixfmt" ];
              };
            };
            # "nixd" = {
            #   # "eval" = { };
            #   "formatting" = {
            #     "command" = [ "nixfmt ." ];
            #   };
            #   "options" = {
            #     "nixos" = {
            #       "expr" = "(builtins.getFlake .#nixosConfigurations.fn.options";
            #     };
            #     "home-manager" = {
            #       "expr" = "(builtins.getFlake.#homeConfigurations.laptop.options";
            #     };
            #     # "target" = {
            #     #   "args" = [ ];
            #     #   "installable" = "(builtins.getFlake \"\${workspaceFolder}\")#nixosConfigurations.<name>.options";
            #     # };
            #   };
            # };
          };
          "[jsonc]" = {
            "editor.defaultFormatter" = "vscode.json-language-features";
          };
          "chat.disableAIFeatures" = false;
          "cSpell.language"="en,de";
          "github.copilot.enable.*" = false;
          "cSpell.dictionaries" = [ "typescript" ];
          "cSpell.userWords" = [ "Linkbetween" ];
          "diffEditor.codeLens" = true;
          "diffEditor.diffAlgorithm" = "advanced";
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.cursorBlinking" = "expand";
          "editor.cursorSmoothCaretAnimation" = "on";
          "editor.cursorSurroundingLinesStyle" = "all";
          "editor.defaultColorDecorators" = "auto";
          "editor.find.autoFindInSelection" = "multiline";
          "editor.fontFamily" = "'FiraCode Nerd Font'";
          "editor.fontLigatures" = true;
          "editor.fontSize" = 12;
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
          "editor.formatOnType" = true;
          "editor.inlineSuggest.enabled" = true;
          "editor.linkedEditing" = true;
          "editor.minimap.maxColumn" = 160;
          "editor.mouseWheelZoom" = true;
          "editor.renderWhitespace" = "all";
          "editor.smoothScrolling" = true;
          "editor.stickyTabStops" = true;
          "editor.suggest.preview" = true;
          "editor.tabCompletion" = "on";
          "editor.tabSize" = 2;
          "editor.wordWrap" = "on";
          "editor.wordWrapColumn" = 160;
          "explorer.incrementalNaming" = "smart";
          "extensions.autoCheckUpdates" = false;
          "extensions.autoUpdates" = false;
          "files.autoGuessEncoding" = true;
          "files.autoSave" = "afterDelay";
          "files.insertFinalNewline" = true;
          "files.trimFinalNewlines" = true;
          "files.trimTrailingWhitespace" = true;
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "gitlens.views.contributors.showStatistics" = true;
          "latex-workshop.formatting.latex" = "tex-fmt";
          "latex-workshop.view.pdf.invert" = 1;
          "latex-workshop.view.pdf.invertMode.enabled" = "auto";
          "ltex.additionalRules.enablePickyRules" = true;
          "ltex.additionalRules.motherTongue" = "de_DE";
          "markdown.extension.completion.enabled" = true;
          "prettier.printWidth" = 160;
          "problems.showCurrentInStatus" = true;
          "redhat.telemetry.enabled" = false;
          "scm.alwaysShowActions" = true;
          "scm.alwaysShowRepositories" = true;
          "search.experimental.notebookSearch" = true;
          "search.smartCase" = true;
          "terminal.integrated.enableImages" = true;
          "terminal.integrated.enableVisualBell" = true;
          "terminal.integrated.mouseWheelZoom" = true;
          "tinymist.lint.enabled" = true;
          "tinymist.preview.cursorIndicator" = true;
          "tinymist.preview.invertColors" = "always";
          "vscode-pets.petColor" = "white";
          "vscode-pets.throwBallWithMouse" = true;
          "workbench.editor.highlightModifiedTabs" = true;
          "workbench.editor.limit.enabled" = true;
          "workbench.list.smoothScrolling" = true;
          "zenMode.showTabs" = "none";
          # "continue.telemetryEnabled" = false;
          # "ltex.language" = "de-DE";
          # "vscode-pets.position" = "panel";
          # "vscode-pets.theme" = "castle";
          # "window.titleBarStyle" = "native";
          # "workbench.colorTheme" = "Dracula";
          # "yaml.schemas" = {
          #   "file:///home/l/.vscode-oss/extensions/Continue.continue/config-yaml-schema.json" =
          #     [ ".continue/**/*.yaml" ];
          # };
        };
        globalSnippets = {
          fixme = {
            body = [ "$LINE_COMMENT FIXME: $0" ];
            description = "Insert a FIXME remark";
            prefix = [ "fixme" ];
          };
        };
        keybindings = [
          {
            key = "ctrl+shift+9";
            command = "testing.runAll";
          }
          {
            key = "ctrl+alt+f";
            command = "leap.search";
          }
          {
            key = "ctrl+c";
            command = "editor.action.clipboardCopyAction";
            when = "textInputFocus";
          }
          # {
          #   "key" = "ctrl+shift+i";
          #   "command" = "-continue.focusEditWithoutClear";
          # }
          {
            key = "ctrl+[Backquote]";
            command = "terminal.focus";
          }
          # {
          #   key = "ctrl+shift+d";
          #   command = "workbench.action.terminal.sendSequence";
          #   args = {
          #     text = ''
          #       cd /home/l/nix;nix run .\#lollypops -- vn
          #     '';
          #   };
          # }
        ];
      };
    };
  };
}
