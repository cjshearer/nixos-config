{ lib, config, ... }:
lib.mkIf config.virtualisation.docker.enable {
  users.users.cjshearer.extraGroups = [ "docker" ];

  # https://discourse.nixos.org/t/dockers-firewall-conflicting-with-nixoss-networking/70086/6
  networking.firewall.trustedInterfaces = [ "docker0" ];
}
