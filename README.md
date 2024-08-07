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
        ├───pixelflasher: package 'PixelFlasher-6.9.8.0'
        └───ytmdesktop: package 'ytmdesktop-2.0.5'
```
