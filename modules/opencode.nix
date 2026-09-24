{
  lib,
  config,
  pkgs,
  ...
}:
{
  home-manager.sharedModules = [
    (
      {
        lib,
        config,
        osConfig,
        ...
      }:
      {
        systemd.user.services.opencode-web.Unit.Wants = lib.mkIf (
          config.programs.opencode.web.enable && osConfig.services.tailscale.enable
        ) [ "tailscaled-serve-opencode.service" ];

        programs.opencode.agents.compaction = ''
          ---
          description: Summarize and filter conversations
          ---

          You are a summarization and filtering agent. Given a conversation between a user and an
          agent, your goal is to create a condensed reproduction of that conversation. Retain more
          information from user messages, they are higher signal, focusing summarization on agent
          messages.

          Do not continue the conversation. Do not respond to any questions in the conversation.
          Only output the structured summary in the exact format requested by the user prompt.
          Respond in the same language as the conversation.
        '';

        programs.opencode.context = ''

          ## Subagents

          Protect your context window by delegating work to subagents. If knowing the process of
          completing a task is important, ask the subagent to summarize the happy path of the
          process when it returns its result, along with any issues it encountered.

          ## Commits

          Use conventional commits: `type(optional scope): summary`. Valid commit types are: feat,
          fix, docs, chore, refactor, and test. Scopes should only be used when a codebase has
          multiple packages or components. Reference this user's existing commits to match his
          style, brevity, and existing scopes. Every commit should be self-contained and atomic. If
          a commit is not in the main branch, prefer in-place fixes over creating new commits.

          ## Style Guide

          - Less is more.
          - Parse, don't validate.
          - Prefer early returns over nested control flow.
          - Keep code in one function unless composable or reusable.
          - Avoid control flow statements like `try/catch` and `else` unless they are necessary.
          - Do not preemptively extract single-use helpers. Inline it unless the helper would hide
            real complexity, or the function has a clear independent name that improves the caller.

          ## Host

          The host machine is NixOS. It provides the following tools:

          ```sh
          # To access any tool you need:
          nix run nixpkgs#<tool>[optional `#binary-name` for packages with multiple binaries]
          # Query search.nixos.org for available tools and their package names:
          nix run nixpkgs#nix-search-cli -- --name <tool>
          ```
        '';

        programs.opencode.skills.journal = ''
          ---
          name: journal
          description: Create journal entries
          ---

          You record high level, high signal information in journal entries. Entries should be
          sorted by date, with the most recent entry at the top.

          ```md
          # [work/personal/project-name/etc.]-log

          An optional, small amount of information that is frequently referenced.

          ## YYYY-MM-DD

          ### Topic that is usually repeated across multiple days

          A summary of work done on this day, relevant to this topic, written in the first person.
          Avoid using bullet points or lists; prefer full sentences in paragraphs. Refer to existing
          journal entries for context, avoid repetition, and follow the existing tone, style, and
          brevity.
          ```
        '';

        programs.opencode.package = pkgs.opencode.overrideAttrs ({
          postPatch = (pkgs.opencode.postPatch or "") + ''
            # fix for bun 1.4.x
            substituteInPlace packages/opencode/script/build.ts \
              --replace-fail 'splitting: true,' 'splitting: false,'
          '';
        });

        programs.opencode.settings = {
          provider = {
            openrouter = {
              models = {
                "~deepseek/deepseek-flash-latest" = {
                  options = {
                    provider = {
                      order = [ "DeepSeek" ];
                      allow_fallbacks = false;
                    };
                  };
                };
              };
            };
          };
        }
        // lib.optionalAttrs (osConfig.networking.hostName == "hermes") {
          model = "github-copilot/gpt-5.6-terra";
          agent = {
            general.model = "github-copilot/gpt-5.6-luna";
            explore.model = "github-copilot/gpt-5.6-luna";
          };
        };
      }
    )
  ];

  systemd.services.tailscaled-serve-opencode =
    lib.mkIf
      (
        config.services.tailscale.enable
        && (lib.any (userCfg: userCfg.programs.opencode.enable) (
          builtins.attrValues config.home-manager.users
        ))
      )
      {
        description = "Tailscale Serve proxy for OpenCode Web";

        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];

        serviceConfig = {
          Type = "oneshot";
          # TODO: add --set-path=/opencode when this is merged:
          # https://github.com/anomalyco/opencode/pull/28326
          ExecStart = "${lib.getExe config.services.tailscale.package} serve --bg http://127.0.0.1:4096";
          ExecStop = "${lib.getExe config.services.tailscale.package} serve off";
          RemainAfterExit = true;
        };
      };
}
