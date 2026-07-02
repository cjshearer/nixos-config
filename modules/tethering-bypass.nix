{
  config,
  lib,
  ...
}:
let
  cfg = config.networking.tetheringBypass;
in
{
  options.networking.tetheringBypass = {
    enable = lib.mkEnableOption "bypass mobile hotspot tethering detection by mangling the IPv4 TTL and IPv6 hop limit";

    ttl = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 65;
      description = ''
        TTL value to set for IPv4 and hop limit for IPv6.
        Carriers detect tethering by checking whether the TTL differs from the
        expected value (usually 64). Setting it to 65 makes tethered traffic
        appear to originate directly from the device.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "net.ipv4.ip_default_ttl" = cfg.ttl;
      "net.ipv6.conf.all.hop_limit" = cfg.ttl;
    };
  };
}
