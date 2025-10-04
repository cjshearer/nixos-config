{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf config.users.cjshearer.programs.vscode.enable {
    home-manager.users.cjshearer.programs.vscode = {
      enable = true;
      package = (
        pkgs.vscode.override {
          commandLineArgs = "--password-store=\"gnome-libsecret\"";
        }
      );

      profiles.default.enableUpdateCheck = false;
      profiles.default.enableExtensionUpdateCheck = false;
      profiles.default.extensions = pkgs.nix4vscode.forVscode (
        [
          "github.copilot"
          "bierner.markdown-mermaid"
          "biomejs.biome"
          "bradlc.vscode-tailwindcss"
          "budparr.language-hugo-vscode"
          "dnut.rewrap-revived"
          "github.copilot-chat"
          "golang.go"
          "jnoortheen.nix-ide"
          "joshbolduc.commitlint"
          "phil294.git-log--graph"
          "rust-lang.rust-analyzer"
          "streetsidesoftware.code-spell-checker"
          "tamasfe.even-better-toml"
          "timonwong.shellcheck"
          "waderyan.gitblame"
        ]
        ++ lib.optionals config.programs.direnv.enable [
          "mkhl.direnv"
        ]
        ++ lib.optionals config.programs.openscad.enable [
          "leathong.openscad-language-support"
        ]
      );

      profiles.default.keybindings = [
        {
          key = "ctrl+f4";
          command = "workbench.action.closeActiveEditor";
        }
        {
          key = "ctrl+w";
          command = "-workbench.action.closeActiveEditor";
        }
        {
          key = "ctrl+k ctrl+alt+s";
          command = "git.stageSelectedRanges";
          when = "editorFocus";
        }
        {
          key = "ctrl+k ctrl+n";
          command = "git.unstageSelectedRanges";
          when = "editorFocus";
        }
        {
          key = "shift+alt+up";
          command = "-editor.action.insertCursorAbove";
          when = "editorTextFocus";
        }
        {
          key = "shift+alt+up";
          command = "editor.action.copyLinesUpAction";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "ctrl+shift+alt+up";
          command = "-editor.action.copyLinesUpAction";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "shift+alt+down";
          command = "editor.action.copyLinesDownAction";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "shift+alt+down";
          command = "-editor.action.insertCursorBelow";
          when = "editorTextFocus";
        }
        {
          key = "ctrl+shift+alt+down";
          command = "-editor.action.copyLinesDownAction";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "f5";
          command = "workbench.action.files.revert";
          when = "editorFocus";
        }
        {
          key = "ctrl+i";
          command = "-editor.action.triggerSuggest";
          when = "editorHasCompletionItemProvider && textInputFocus && !editorReadonly && !suggestWidgetVisible";
        }
      ];

      profiles.default.userSettings = {
        "[markdown]" = {
          "rewrap.autoWrap.enabled" = false;
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "[yaml]" = {
          "editor.autoIndent" = "advanced";
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };
        "biome.lsp.bin" = lib.getExe pkgs.biome;
        "cSpell.diagnosticLevel" = "Hint";
        "cSpell.diagnosticLevelFlaggedWords" = "Hint";
        "cSpell.textDecorationColor" = "royalblue";
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "explicit";
        };
        "editor.formatOnSave" = true;
        "editor.formatOnSaveMode" = "file";
        "editor.guides.bracketPairs" = true;
        "editor.inlineSuggest.enabled" = true;
        "editor.rulers" = [ 100 ];
        "editor.tabSize" = 2;
        "editor.wordWrap" = "bounded";
        "editor.wordWrapColumn" = 100;
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
        "extensions.autoUpdate" = false;
        "extensions.ignoreRecommendations" = true;
        "files.exclude" = {
          "**/.git" = false;
        };
        "git.autofetch" = true;
        "git.confirmSync" = true;
        "git.terminalGitEditor" = true;
        "github.copilot.enable" = {
          "*" = true;
          "plaintext" = false;
          "markdown" = true;
          "scminput" = false;
        };
        "javascript.inlayHints.parameterNames.enabled" = "literals";
        "javascript.inlayHints.propertyDeclarationTypes.enabled" = true;
        "javascript.referencesCodeLens.showOnAllFunctions" = true;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "nix.enableLanguageServer" = true;
        "nix.hiddenLanguageServerErrors" = [
          "textDocument/documentSymbol"
        ];
        "nix.serverPath" = lib.getExe pkgs.nil;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "window.customMenuBarAltFocus" = false;
        "window.titleBarStyle" = "custom";
        "window.zoomLevel" = 0.5;
      };
    };

    home-manager.users.cjshearer.services.gnome-keyring.enable = true;
  };
}
