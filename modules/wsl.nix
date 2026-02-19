{ lib, config, nixos-wsl, ... }: {
  imports = [ nixos-wsl.nixosModules.default ];

  config = lib.mkIf config.wsl.enable {  
    wsl.defaultUser = "cjshearer";
    wsl.interop.register = true;
    wsl.ssh-agent.enable = true;
  };
}

