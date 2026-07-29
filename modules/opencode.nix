{ lib, config, ... }: {
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
