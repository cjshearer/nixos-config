{ osConfig, ... }: {
  programs.ssh.enable = true;
  programs.ssh.matchBlocks."github.com" = {
    hostname = "ssh.github.com";
    port = 443;
    user = "git";
    identityFile = [ "~/.ssh/${osConfig.networking.hostName}" ];
  };
}
