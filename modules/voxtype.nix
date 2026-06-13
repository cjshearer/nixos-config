{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.users.cjshearer.services.voxtype.enable = lib.mkEnableOption "voxtype";

  config = lib.mkIf config.users.cjshearer.services.voxtype.enable {
    home-manager.users.cjshearer.services.voxtype = {
      enable = true;
      package = pkgs.voxtype-vulkan;
      loadModels = [ "base.en" ];
      # awaiting https://github.com/nix-community/home-manager/pull/9484
      environment.PATH = "${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.which
          pkgs.wl-clipboard
          pkgs.wtype
        ]
      }:$PATH";
      settings = {
        output.mode = "paste";
        output.restore_clipboard = true;
        output.shift_enter_newlines = true;
        vad.enable = true;
      };
    };
  };
}
