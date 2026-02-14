{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.services.logiops;
in
{
  options.services.logiops.enable = mkEnableOption "logiops";

  config = mkIf cfg.enable {
    services.udev.packages = [ pkgs.logitech-udev-rules ];

    # We restart logiops when a Logitech device connects to avoid timing issues that prevent the
    # mouse from working on reboot:
    # https://github.com/PixlOne/logiops/issues/522
    services.udev.extraRules = ''
      # Logitech via USB receiver
      ACTION=="add|change", SUBSYSTEM=="hidraw", SUBSYSTEMS=="usb", ATTRS{idVendor}=="046d", \
        RUN+="${pkgs.systemd}/bin/systemctl restart --no-block logiops.service"

      # Logitech via Bluetooth (BlueZ UHID path 0005:046D:...)
      ACTION=="add|change", SUBSYSTEM=="hidraw", KERNELS=="0005:046D:*", \
        RUN+="${pkgs.systemd}/bin/systemctl restart --no-block logiops.service"
    '';

    home-manager.users.cjshearer.systemd.user.services.logiops = {
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
