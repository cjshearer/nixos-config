{ pkgs, ... }:
builtins.mapAttrs (name: _: (pkgs.callPackage (./. + "/by-name/${name}/default.nix") { })) (
  builtins.readDir ./by-name
)
