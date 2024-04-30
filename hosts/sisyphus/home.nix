{
  programs.blender.enable = true;
  programs.discord.enable = true;
  programs.git.enable = true;
  programs.google-chrome.enable = true;
  programs.hyprshot.enable = true;
  programs.kitty.enable = true;
  programs.libreoffice.enable = true;
  programs.obsidian.enable = true;
  programs.pavucontrol.enable = true;
  programs.rofi.enable = true;
  programs.ssh.enable = true;
  programs.thunderbird.enable = true;
  programs.vscode.enable = true;
  programs.waybar.enable = true;

  services.cliphist.enable = true;
  services.mako.enable = true;

  wayland.windowManager.hyprland.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
}
