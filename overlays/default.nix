{ inputs, ... }: {
  nixpkgs.overlays = [
    (final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [
          "openssl-1.0.1u" # required by ideamaker
          "curl-7.47.0" # required by ideamaker
        ];
      };
    })
    (final: _prev: import ../pkgs { pkgs = _prev.pkgs.unstable; })
    inputs.nix-vscode-extensions.overlays.default
  ];
}
