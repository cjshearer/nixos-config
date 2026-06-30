{ lib, config, ... }:
lib.mkIf config.virtualisation.docker.enable {
  home-manager.sharedModules = [
    (
      { lib, ... }:
      {
        options.programs.docker.enable = lib.mkEnableOption "access to the docker socket";
      }
    )
  ];

  # Grant docker socket access only to users who opt in via Home Manager, keyed off each
  # user's own `home.username` instead of hardcoding a username.
  users.groups.docker.members = lib.pipe config.home-manager.users [
    (lib.filterAttrs (_: user: user.programs.docker.enable))
    (lib.mapAttrsToList (_: user: user.home.username))
  ];

  # https://discourse.nixos.org/t/dockers-firewall-conflicting-with-nixoss-networking/70086/6
  networking.firewall.trustedInterfaces = [ "docker0" ];

  # WSL mirrored mode: do not DNAT packets from WSL2's loopback0
  # https://github.com/moby/moby/issues/48056#issuecomment-2315995230
  virtualisation.docker.daemon.settings.userland-proxy = !config.wsl.enable;
}
