{ inputs, pkgs, ... }: {
  nixpkgs.overlays = [
    (final: _prev: {
      nixpkgs = import inputs.nixpkgs {
        system = final.system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [
          "openssl-1.0.1u" # required by ideamaker
          "curl-7.47.0" # required by ideamaker
        ];
      };
    })
    (final: _prev: import ../pkgs { inherit pkgs; })
    inputs.nix-vscode-extensions.overlays.default
  ];
}
