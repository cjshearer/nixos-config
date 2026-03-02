{ lib, config, ... }:
lib.mkIf config.virtualisation.docker.enable {
  users.users.cjshearer.extraGroups = [ "docker" ];

  # https://discourse.nixos.org/t/dockers-firewall-conflicting-with-nixoss-networking/70086/6
  networking.firewall.trustedInterfaces = [ "docker0" ];

  # WSL mirrored mode: do not DNAT packets from WSL2's loopback0
  # https://github.com/moby/moby/issues/48056#issuecomment-2315995230
  virtualisation.docker.daemon.settings.userland-proxy = !config.wsl.enable;
}
