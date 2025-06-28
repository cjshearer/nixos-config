{ inputs, lib, config, systemConfig, pkgs, ... }: with lib;
let
  cfg = config.programs.vscode;
in
{
  options.programs.vscode.enable = mkEnableOption "vscode";

  config = mkIf cfg.enable {
    home-manager.users.cjshearer.programs.vscode = {
      enable = true;
      package = (pkgs.vscodium.override {
        commandLineArgs = "--password-store=\"gnome-libsecret\"";
      });
      extensions =
        (with pkgs.vscode-extensions; [
          bierner.markdown-mermaid
          github.copilot
          github.copilot-chat
          golang.go
          jnoortheen.nix-ide
          # Failed to find package "@vscode/vsce-sign-linux-x64" on the file system
          # rust-lang.rust-analyzer 
          # TODO: add or wait for dnut.rewrap-revived to be added to vscode-extensions and replace:
          stkb.rewrap
          streetsidesoftware.code-spell-checker
          tamasfe.even-better-toml
          timonwong.shellcheck
          waderyan.gitblame
        ]) ++ (with pkgs.vscode-marketplace; [
          biomejs.biome
          budparr.language-hugo-vscode
          joshbolduc.commitlint
          phil294.git-log--graph
          bradlc.vscode-tailwindcss
        ]) ++ lib.optionals config.programs.direnv.enable (with pkgs.vscode-extensions; [
          mkhl.direnv
        ]);

      keybindings = [
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

      userSettings = {
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
        "nix.formatterPath" = lib.getExe pkgs.nixpkgs-fmt;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "window.customMenuBarAltFocus" = false;
        "window.titleBarStyle" = "custom";
        "window.zoomLevel" = 0.5;
      };
    };
  };
}
