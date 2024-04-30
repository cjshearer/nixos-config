{ inputs, ... }: {
  imports = [
    ./blender.nix
    ./chrome.nix
    ./cliphist.nix
    ./discord.nix
    ./font-awesome.nix
    ./git.nix
    ./hypr.nix
    ./hyprshot.nix
    ./kitty.nix
    ./libreoffice.nix
    ./mako.nix
    ./obsidian.nix
    ./pavucontrol.nix
    ./rofi.nix
    ./ssh.nix
    ./thunderbird.nix
    ./vscode.nix
    ./waybar.nix
  ];

  nixpkgs = {
    overlays = [
      inputs.nix-vscode-extensions.overlays.default
      (final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      })
    ];

    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  programs.home-manager.enable = true;
}
