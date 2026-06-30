{
  config,
  lib,
  ncro,
  self,
  ...
}:
{
  imports = [ ncro.nixosModules.default ];

  # We expose the local Nix store as an HTTP binary cache so other hosts can pull from us.
  services.nix-serve.enable = true;

  # Because Nix requests packages from substituters sequentially, it can take up to
  # `M * connection-timeout` seconds to begin downloading packages using the built-in substituters
  # list. To avoid this, we offload routing to a local HTTP proxy that races all upstream caches
  # and routes to the fastest one.
  #
  # Hopefully Nix will support this natively in the future:
  # https://github.com/NixOS/nix/issues/15419
  services.ncro = {
    enable = true;
    settings = {
      server.listen = "127.0.0.1:6276";
      # We prioritize peers over community caches, both to reduce their costs, but also because
      # our peers are usually nearer and thus faster.
      upstreams = [
        {
          url = "https://nix-community.cachix.org";
          priority = 20;
          public_key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
        }
        {
          url = "https://cache.nixos.org";
          priority = 10;
        }
      ]
      # If this is a tailscale-enabled host, we add all other tailscale-enabled hosts as upstreams,
      # so they can share each other's build caches.
      ++
        lib.map
          (host: {
            url = "http://${host}:${builtins.toString config.services.nix-serve.port}";
            priority = 0;
          })
          (
            lib.optionals config.services.tailscale.enable (
              lib.remove config.networking.hostName (
                builtins.attrNames (
                  lib.filterAttrs (
                    _name: host: host.config.services.tailscale.enable or false
                  ) self.nixosConfigurations
                )
              )
            )
          );
    };
  };

  nix.settings.substituters = [
    "http://${config.services.ncro.settings.server.listen}?trusted=true"
  ];
}
