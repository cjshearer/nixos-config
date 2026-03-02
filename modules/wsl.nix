{
  lib,
  config,
  nixos-wsl,
  ...
}:
{
  imports = [ nixos-wsl.nixosModules.default ];

  # .wslconfig
  # [wsl2]
  # networkingMode=Mirrored
  config = lib.mkIf config.wsl.enable {
    wsl.defaultUser = "cjshearer";
    wsl.interop.register = true;
    wsl.ssh-agent.enable = true;
  };
}
