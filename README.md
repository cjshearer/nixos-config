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
│   └───sisyphus: NixOS configuration
└───packages
    └───x86_64-linux
        ├───ideamaker: package 'ideamaker-5.2.1.8560'
        └───prepare-nixos-disk: package 'prepare-nixos-disk'
```

## Common Commands

```sh
# build and deploy local configuration
sudo nixos-rebuild switch --flake .

# build target configuration locally and push over ssh
nixos-rebuild switch --flake . --target-host user@targetHost --use-remote-sudo

# create NixOS installation media
sudo nix run .#prepare-nixos-disk
nix build .#nixosConfigurations.clotho.config.system.build.isoImage
sudo cp result/iso/*.iso /dev/sdX

# initial NixOS installation:
# 1. disable secure boot
# 2. boot from the installation media
# 3. connect to the network (`nmtui` for wireless or share internet from phone over USB)
# TODO: script this or use disko:
# 4. follow remaining instructions starting from here:
#    https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning
# 5. setup rbw using client_id, client_secret, and TOTP in Bitwarden
rbw register
rbw login

# secrets management, on reboot or restart of certain systemd unit (nixos-rebuild switch):
# 1. log into rbw
# 2. systemd unit pushes select rbw credentials from systemd unit to various encrypted credential
#    files in `/run/bitwarden/secrets` (https://systemd.io/CREDENTIALS/)
# 3. reference secrets using standard NixOS pattern of referencing a file
#    (e.g. `readFile /run/bitwarden/secrets/my-secret`)
```

> [!TIP]
> Copying `/nix/store` paths during remote deployments [requires](https://nixos.wiki/wiki/Nixos-rebuild) that the ssh user be in `nix.settings.trusted-users`.

## Upstream Contributions

- [ideamaker: init at 4.3.3](https://github.com/NixOS/nixpkgs/pull/309130)
- [pixelflasher: init at 7.9.2.4](https://github.com/NixOS/nixpkgs/pull/336191)
- [ytmdesktop: init at 2.0.5](https://github.com/NixOS/nixpkgs/pull/317309)
