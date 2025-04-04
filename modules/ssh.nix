{ systemConfig, lib, config, ... }: with lib;
let
  cfg = config.programs.ssh;
in
{
  options.programs.ssh.enable = mkEnableOption "ssh";

  config = mkIf cfg.enable {
    home-manager.users.${systemConfig.username}.programs.ssh = {
      enable = true;
      matchBlocks."github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityFile = [ "~/.ssh/${systemConfig.hostname}" ];
      };
    };
  };
}
