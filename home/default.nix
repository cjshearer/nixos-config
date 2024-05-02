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
    ./ideamaker.nix
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

  programs.home-manager.enable = true;
}
