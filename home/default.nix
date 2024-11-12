{ inputs, pkgs, ... }: {
  imports = [
    ./blender.nix
    ./chrome.nix
    ./direnv.nix
    ./discord.nix
    ./font-awesome.nix
    ./git.nix
    ./libreoffice.nix
    ./obsidian.nix
    ./ssh.nix
    ./thunderbird.nix
    ./vscode.nix
  ];

  programs.home-manager.enable = true;

  gtk = {
    enable = true;
    iconTheme.name = "Adwaita-dark";
    iconTheme.package = pkgs.adwaita-icon-theme;
    theme.name = "Adwaita-dark";
    theme.package = pkgs.gnome-themes-extra;
  };
}
