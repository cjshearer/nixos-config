{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/914a31f1-92a4-461b-ad89-b81e6519e277";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1E23-D587";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = "x86_64-linux";

  users.cjshearer.programs.atuin.enable = true;
  users.cjshearer.programs.git.enable = true;
  users.cjshearer.programs.ssh.enable = true;
  users.cjshearer.programs.thunderbird.enable = true;
  users.cjshearer.programs.vscode.enable = true;

  users.cjshearer.services.rclone.onedrive.enable = true;
  users.cjshearer.services.rclone.onedrive.symlink.enable = true;
  users.cjshearer.services.remmina.enable = true;

  programs.direnv.enable = true;
  programs.discord.enable = true;
  programs.google-chrome.enable = true;
  programs.light.brightnessKeys.enable = true;
  programs.light.enable = true;
  programs.obsidian.enable = true;
  programs.ytmdesktop.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.tailscale.enable = true;

  swapDevices = [ { device = "/dev/disk/by-uuid/f957ab19-5cde-41d7-8866-e0d85c25bc12"; } ];

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
