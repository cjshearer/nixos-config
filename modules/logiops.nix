{ lib, pkgs, systemConfig, config, ... }:
with lib;
let
  cfg = config.services.logiops;
in
{
  options.services.logiops.enable = mkEnableOption "logiops";

  config = mkIf cfg.enable {
    services.udev.packages = [ pkgs.logitech-udev-rules ];

    # we restart logiops when a Logitech device connects to avoid timing issues that prevent the
    # mouse from working on reboot
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="input", ATTRS{id/vendor}=="046d", RUN{program}="${pkgs.systemd}/bin/systemctl --machine=${systemConfig.username}@.host --user restart logiops.service"
    '';

    home-manager.users.${systemConfig.username}.systemd.user.services.logiops = {
      Unit = {
        Description = "An unofficial userspace driver for HID++ Logitech devices";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.logiops_0_2_3}/bin/logid";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    environment.etc."logid.cfg".text = ''
      devices: ({
        name: "Wireless Mouse MX Master 3";
        dpi: 3000; // max 4000
        thumbwheel: {
          invert: false;
        };
        smartshift: {
          on: true;
          threshold: 10;
        };
        # fixes inconsistent scrolling
        # https://github.com/PixlOne/logiops/issues/116#issuecomment-1902559105
        hiresscroll: {
          hires: false;
          invert: false;
          target: true;
          up: {
            mode: "Axis";
            axis: "REL_WHEEL";
            axis_multiplier: 1.0;
          },
          down: {
            mode: "Axis";
            axis: "REL_WHEEL";
            axis_multiplier: -1.0;
          }
        };

        buttons: (
          // Thumb button
          {
            cid: 0xc3;
            action =
            {
                type: "Keypress";
                keys: ["KEY_O"];
            };
          },

          // Top button
          {
            cid: 0xc4;
            action =
            {
                type: "Keypress";
                keys: ["KEY_P"];
            };
          }
        );
      });
    '';
  };
}

