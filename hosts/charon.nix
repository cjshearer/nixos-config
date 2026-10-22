{
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_scsi"
  ];
  boot.loader.systemd-boot.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8a67d44b-5f63-4bed-bd32-7cc652db6452";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DBB7-EB52";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  networking.networkmanager.enable = true;

  nixpkgs.hostPlatform = "aarch64-linux";

  services.immich.enable = true;
  services.qbittorrent.enable = true;
  services.tailscale.enable = true;

  home-manager.users.cjshearer.programs.atuin.enable = true;
  home-manager.users.cjshearer.programs.git.enable = true;
  home-manager.users.cjshearer.programs.jujutsu.enable = true;
  home-manager.users.cjshearer.programs.helix.enable = true;
  home-manager.users.cjshearer.programs.lazygit.enable = true;
  home-manager.users.cjshearer.programs.ssh.enable = true;
  home-manager.users.cjshearer.programs.tmux.enable = true;

  home-manager.users.cjshearer.services.vscode-server.enable = true;

  users.cjshearer.services.syncthing.enable = true;

  # Charon is always on, so it is the single host that holds the game folders
  # and mirrors them to OneDrive. The desktops sync the folders but never push.
  users.cjshearer.programs.dusklight.replicate = true;
  users.cjshearer.programs.pcsx2.replicate = true;
  users.cjshearer.services.rclone.enable = true;

  time.timeZone = "America/New_York";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home-manager.users.cjshearer.home.stateVersion = "24.05";
}
