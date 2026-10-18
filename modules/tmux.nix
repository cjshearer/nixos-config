{
  home-manager.sharedModules = [
    (
      { lib, config, ... }:
      lib.mkIf config.programs.tmux.enable {
        programs.tmux = {
          terminal = "tmux-256color";
          historyLimit = 50000;
          mouse = true;
          extraConfig = ''
            set -g status off
            set -g set-clipboard on
          '';
        };

        programs.bash.bashrcExtra = ''
          t() {
            tmux new-session -A -s main "$@"
          }
        '';
      }
    )
  ];
}
