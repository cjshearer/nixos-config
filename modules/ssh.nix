{
  config,
  lib,
  ...
}:
{
  options.users.cjshearer.programs.ssh.enable = lib.mkEnableOption "ssh";

  config = lib.mkIf config.users.cjshearer.programs.ssh.enable {
    home-manager.users.cjshearer.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".IdentityFile = [ "~/.ssh/${config.networking.hostName}" ];
    };
  };
}
