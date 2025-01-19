{ inputs, pkgs, ... }: {
  nixpkgs.overlays = [
    (final: _prev: import ../pkgs { inherit pkgs; })
    inputs.nix-vscode-extensions.overlays.default
  ];
}
