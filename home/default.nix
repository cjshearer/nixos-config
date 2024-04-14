{
  imports = [
    ./browser.nix
    ./discord.nix
    ./email.nix
    ./git.nix
    ./gnome.nix
    ./vscode.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  programs.home-manager.enable = true;
}
