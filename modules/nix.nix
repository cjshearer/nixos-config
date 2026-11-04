{
  config,
  lib,
  self,
  ...
}:
let
  buildPeers = lib.filterAttrs (
    name: host:
    # The current host is never a build peer
    name != config.networking.hostName
    # Builds are distributed over tailscale
    && host.config.services.tailscale.enable
    # These hosts are usually online
    && builtins.elem name [
      "sisyphus"
      "charon"
    ]
  ) self.nixosConfigurations;
in
{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ "cjshearer" ];

  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;
  nix.buildMachines = lib.mapAttrsToList (name: host: {
    hostName = name;
    protocol = "ssh-ng";
    system = host.config.nixpkgs.hostPlatform.system;
    sshUser = "cjshearer";
    maxJobs = 4;
  }) buildPeers;

  nixpkgs.config.allowUnfree = true;
}
