# nixos-config

```sh
$ tree -v --dirsfirst -L 1
.
├── dev           # `nix develop .#package & source interactive.bash`
├── home          # wrap packages for home-level installation
├── hosts         # enable system and home manager modules for a host
├── overlays      # add to or modify nixpkgs
├── pkgs          # define custom packages
├── system        # wrap packages for system-level installation
├── LICENSE       # MIT
├── README.md     # *you are here
├── flake.lock    # pin inputs' versions
└── flake.nix     # config entrypoint

$ nix flake show
.
├───nixosConfigurations
│   ├───athamas: NixOS configuration
│   ├───charon: NixOS configuration
│   └───sisyphus: NixOS configuration
└───packages
    └───x86_64-linux
        ├───hyprec: package 'hyprec'
        └───pixelflasher: package 'pixelflasher-7.5.0.0'
```

## Common Commands

```sh
# build and deploy local configuration
sudo nixos-rebuild switch --flake .

# build target configuration locally and push over ssh
nixos-rebuild switch --flake . --target-host user@targetHost --use-remote-sudo
```

> [!TIP]
> Copying `/nix/store` paths during remote deployments [requires](https://nixos.wiki/wiki/Nixos-rebuild) that the ssh user be in `nix.settings.trusted-users`.

## Upstream Contributions

- [ideamaker: init at 4.3.3](https://github.com/NixOS/nixpkgs/pull/309130)
- [pixelflasher: init at 7.5.0.0](https://github.com/NixOS/nixpkgs/pull/336191) (open, add a 👍 if you want it merged)
- [ytmdesktop: init at 2.0.5](https://github.com/NixOS/nixpkgs/pull/317309)
