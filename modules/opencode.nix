{ lib, config, pkgs, ... }: {
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
        } // lib.optionalAttrs (osConfig.networking.hostName == "hermes") {
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
