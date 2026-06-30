{
  home-manager.sharedModules = [
    (
      {
        lib,
        config,
        osConfig,
        ...
      }:
      lib.mkIf config.programs.ssh.enable {
        programs.ssh.enableDefaultConfig = false;
        programs.ssh.settings."*".IdentityFile = [ "~/.ssh/${osConfig.networking.hostName}" ];
      }
    )
  ];
}
