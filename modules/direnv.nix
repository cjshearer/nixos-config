{ lib, config, ... }:
lib.mkIf config.programs.direnv.enable {
  programs.direnv = {
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };
}
