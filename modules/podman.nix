{ lib, config, ... }:
lib.mkIf config.virtualisation.podman.enable {
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.dockerCompat = true;
}
