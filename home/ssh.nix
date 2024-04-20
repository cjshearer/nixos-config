{ systemConfig, lib, config, ... }: lib.mkIf config.programs.ssh.enable {
  programs.ssh.matchBlocks."github.com" = {
    hostname = "ssh.github.com";
    port = 443;
    user = "git";
    identityFile = [ "~/.ssh/${systemConfig.hostname}" ];
  };
}
