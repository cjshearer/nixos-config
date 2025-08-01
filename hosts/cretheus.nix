{ nixos-hardware, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/fa387430-ca2c-4ea4-9f8e-8155ef0b3c68";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/21C8-37BF";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  users.cjshearer.programs.atuin.enable = true;
  users.cjshearer.programs.git.enable = true;
  users.cjshearer.programs.kicad.enable = true;
  users.cjshearer.programs.rclone.enable = true;
  users.cjshearer.programs.ssh.enable = true;
  users.cjshearer.programs.vscode.enable = true;
  users.cjshearer.services.remmina.enable = true;

  programs.blender.enable = true;
  programs.direnv.enable = true;
  programs.discord.enable = true;
  programs.freecad.enable = true;
  programs.google-chrome.enable = true;
  programs.ytmdesktop.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.logiops.enable = true;
  services.pipewire.enable = true;
  services.tailscale.enable = true;

  time.timeZone = "America/New_York";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home-manager.users.cjshearer.home.stateVersion = "25.11";
}
