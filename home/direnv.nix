{ lib, config, ... }: lib.mkIf config.programs.direnv.enable {
  programs = {
    bash.enable = true;
    direnv = {
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
