{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.logiops;
in
{
  options.services.logiops.enable = mkEnableOption "logiops";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.logiops ];

    systemd.services.logiops = {
      description = "An unofficial userspace driver for HID++ Logitech devices";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.logiops}/bin/logid";
      };
      wantedBy = [ "multi-user.target" ];
    };

    environment.etc."logid.cfg".text = ''
      devices: ({
        name: "Wireless Mouse MX Master 3";
        dpi: 1000; // max 4000
        thumbwheel: {
          invert: false;
        };
        smartshift: {
          on: true;
          threshold: 10;
        };
        hiresscroll: {
          hires: true;
          target: false;
        };

        buttons: (
          // Thumb button
          {
            cid: 0xc3;
            action =
            {
                type: "Keypress";
                keys: ["KEY_KPLEFTPAREN"];
            };
          },

          // Top button
          {
            cid: 0xc4;
            action =
            {
                type: "Keypress";
                keys: ["KEY_KPRIGHTPAREN"];
            };
          }
        );
      });
    '';
  };
}

