{
  imports = [
    ./chrome.nix
    ./cliphist.nix
    ./discord.nix
    ./font-awesome.nix
    ./git.nix
    ./hypr.nix
    ./kitty.nix
    ./mako.nix
    ./pavucontrol.nix
    ./rofi.nix
    ./ssh.nix
    ./thunderbird.nix
    ./vscode.nix
    ./waybar.nix
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
