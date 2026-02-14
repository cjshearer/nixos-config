# nixos-config

```sh
$ tree -v --dirsfirst -L 1
.
├── dev           # `nix develop .#package & source interactive.bash`
├── hosts         # enable modules for a host
├── modules       # custom modules mixing nixos and home-manager
├── pkgs          # define custom packages
├── LICENSE       # MIT
├── README.md     # *you are here
├── flake.lock    # pin inputs' versions
└── flake.nix     # config entrypoint

$ nix flake show | grep -v omitted
.
├───nixosConfigurations
│   ├───athamas: NixOS configuration
│   ├───charon: NixOS configuration
│   ├───clotho: NixOS configuration
│   ├───cretheus: NixOS configuration
│   └───sisyphus: NixOS configuration
├───overlays
│   └───packages: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    ├───aarch64-linux
    ├───armv6l-linux
    ├───armv7l-linux
    ├───i686-linux
    ├───powerpc64le-linux
    ├───riscv64-linux
    ├───x86_64-darwin
    ├───x86_64-freebsd
    └───x86_64-linux
        ├───cadquery: package 'python3.13-cadquery-2.6.1'
        ├───cadquery-ocp: package 'python3.13-cadquery-ocp-7.8.1.2'
        ├───cq-editor: package 'cq-editor-0.6.2'
        ├───google-photos-takeout-helper: package 'google-photos-takeout-helper-5.0.5'
        ├───ideamaker: package 'ideamaker-5.2.2.8570'
        ├───prepare-nixos-disk: package 'prepare-nixos-disk'
        ├───trame: package 'python3.13-trame-3.12.0'
        ├───trame-client: package 'python3.13-trame-client-3.11.2'
        ├───trame-common: package 'python3.13-trame-common-1.1.1'
        ├───trame-server: package 'python3.13-trame-server-3.10.0'
        ├───trame-vtk: package 'python3.13-trame-vtk-2.11.1'
        └───trame-vuetify: package 'python3.13-trame-vuetify-3.2.1'
```

## Common Commands

```sh
# build and deploy local configuration
sudo nixos-rebuild switch --flake .

# build target configuration locally and push over ssh
nixos-rebuild switch --flake . --target-host user@targetHost --ask-sudo-password

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

- [cq-editor: init at 0.6.2](https://github.com/NixOS/nixpkgs/pull/486070)
- [cadquery: init at 2.6.1](https://github.com/NixOS/nixpkgs/pull/486070)
- [ideamaker: 4.3.3.6560 -> 5.2.2.8570](https://github.com/NixOS/nixpkgs/pull/388453)
- [ideamaker: init at 4.3.3](https://github.com/NixOS/nixpkgs/pull/309130)
- [pixelflasher: init at 7.9.2.4](https://github.com/NixOS/nixpkgs/pull/336191)
- [ytmdesktop: init at 2.0.5](https://github.com/NixOS/nixpkgs/pull/317309)
