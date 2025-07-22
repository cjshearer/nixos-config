# nixos-config

```sh
$ tree -v --dirsfirst -L 1
.
├── dev           # `nix develop .#package & source interactive.bash`
├── hosts         # enable modules for a host
├── modules       # custom modules mixing nixos and home-manager
├── overlays      # add to or modify nixpkgs
├── pkgs          # define custom packages
├── LICENSE       # MIT
├── README.md     # *you are here
├── flake.lock    # pin inputs' versions
└── flake.nix     # config entrypoint

$ nix flake show
.
├───nixosConfigurations
│   ├───athamas: NixOS configuration
│   ├───charon: NixOS configuration
│   ├───clotho: NixOS configuration
│   ├───cretheus: NixOS configuration
│   └───sisyphus: NixOS configuration
└───packages
    └───x86_64-linux
        ├───ideamaker: package 'ideamaker-5.2.2.8570'
        └───prepare-nixos-disk: package 'prepare-nixos-disk'
```

## Common Commands

```sh
# build and deploy local configuration
sudo nixos-rebuild switch --flake .

# build target configuration locally and push over ssh
nixos-rebuild switch --flake . --target-host user@targetHost --use-remote-sudo

# provisioning a new host with a USB drive:
sudo nix run .#prepare-nixos-disk
nix build .#nixosConfigurations.clotho.config.system.build.isoImage
sudo cp result/iso/*.iso /dev/sdX
# don't forget to disable secure boot
# set passwd
# sudo tailscale login --qr
# follow https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning

```

> [!TIP]
> Copying `/nix/store` paths during remote deployments [requires](https://nixos.wiki/wiki/Nixos-rebuild) that the ssh user be in `nix.settings.trusted-users`.

## Upstream Contributions

- [ideamaker: 5.1.4.8480 -> 5.2.2.8570](https://github.com/NixOS/nixpkgs/pull/388453)
- [ideamaker: init at 4.3.3](https://github.com/NixOS/nixpkgs/pull/309130)
- [pixelflasher: init at 7.9.2.4](https://github.com/NixOS/nixpkgs/pull/336191)
- [ytmdesktop: init at 2.0.5](https://github.com/NixOS/nixpkgs/pull/317309)
