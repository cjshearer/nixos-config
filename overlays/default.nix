{ pkgs, nix4vscode, ... }:
{
  nixpkgs.overlays = [
    (final: _prev: import ../pkgs { inherit pkgs; })
    nix4vscode.overlays.default
  ];
}
