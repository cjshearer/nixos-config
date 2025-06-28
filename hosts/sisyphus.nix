{ systemConfig, config, lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/6c060c58-52b2-4a2d-854c-5f5288ea1351";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/659F-14A0";
      fsType = "vfat";
    };

  hardware.amdgpu.opencl.enable = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.keyboard.zsa.enable = true;

  networking.useDHCP = lib.mkDefault true;

  programs.atuin.enable = true;
  # programs.blender.enable = true;
  programs.direnv.enable = true;
  programs.discord.enable = true;
  programs.freecad.enable = true;
  programs.citrix_workspace.enable = true;
  programs.git.enable = true;
  programs.google-chrome.enable = true;
  programs.ideamaker.enable = true;
  programs.kicad.enable = true;
  programs.ledger-live-desktop.enable = true;
  programs.libreoffice.enable = true;
  programs.obsidian.enable = true;
  programs.picard.enable = true;
  programs.pixelflasher.enable = true;
  programs.qbittorrent.enable = true;
  programs.remmina.enable = true;
  programs.ssh.enable = true;
  programs.steam.enable = true;
  programs.thunderbird.enable = true;
  programs.vscode.enable = true;
  programs.ytmdesktop.enable = true;
  # programs.zoom-us.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.liquidctl.enable = true;
  services.logiops.enable = true;
  services.pipewire.enable = true;
  services.rclone.enable = true;
  services.tailscale.enable = true;

  swapDevices = [ ];

  time.timeZone = "America/New_York";

  nixpkgs.config.rocmSupport = true;
  nixpkgs.hostPlatform = "x86_64-linux";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home-manager.users.${systemConfig.username}.home.stateVersion = "23.11";
}
