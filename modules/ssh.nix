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
      matchBlocks."github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityFile = [ "~/.ssh/${config.networking.hostName}" ];
      };
    };
  };
}
