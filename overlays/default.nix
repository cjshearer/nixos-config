{ pkgs, nix4vscode, ... }:
{
  nixpkgs.overlays = [
    (final: _prev: import ../pkgs { inherit pkgs; })
    nix4vscode.overlays.default
    (final: prev: {
      kicad-unstable = (
        prev.kicad-unstable.override {
          srcs = {
            kicadVersion = "9.0.6";
            kicad = prev.fetchFromGitLab {
              group = "kicad";
              owner = "code";
              repo = "kicad";
              rev = "f84f0b913d131adc6111ba7e3aabd5dc7053f21f";
              sha256 = "xkquQ7Z+2we1VXQzNSpNFAnAfAA6LdyOTot8I2l8b2k=";
            };
            libVersion = "9.0.6";
            symbols = prev.fetchFromGitLab {
              group = "kicad";
              owner = "libraries";
              repo = "kicad-symbols";
              rev = "e92aabf81dc1af151fa452a33679dcb42b93fcbd";
              sha256 = "03k3y86mgc10ir5l1gdzc0r7w1gg7iavb1zl31kgfh9hnfmgv06w";
            };
            templates = prev.fetchFromGitLab {
              group = "kicad";
              owner = "libraries";
              repo = "kicad-templates";
              rev = "710c895e2f3be0ec366139bf33c9ca711c990630";
              sha256 = "0zs29zn8qjgxv0w1vyr8yxmj02m8752zagn4vcraqgik46dwg2id";
            };
            footprints = prev.fetchFromGitLab {
              group = "kicad";
              owner = "libraries";
              repo = "kicad-footprints";
              rev = "0836ca140b415055e373de97c466961088d8972a";
              sha256 = "0jzkrmzkxv3kqqmkpq5dpp3shy9ajfg1b1yzhk4ddzvy8l05qym4";
            };
            packages3d = prev.fetchFromGitLab {
              group = "kicad";
              owner = "libraries";
              repo = "kicad-packages3D";
              rev = "1e24671163ce0f44bf57b46445c7e7be1a95977d";
              sha256 = "04hw6b4hyl2plfgynin3dv7siqml4341264wz2wngddszq8z32ki";
            };
          };
        }
      );
    })
  ];
}
