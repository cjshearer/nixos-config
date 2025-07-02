{ pkgs, nix-vscode-extensions, ... }: {
  nixpkgs.overlays = [
    (final: _prev: import ../pkgs { inherit pkgs; })
    nix-vscode-extensions.overlays.default
  ];
}
