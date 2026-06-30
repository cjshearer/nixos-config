{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      lib.mkIf config.services.voxtype.enable {
        services.voxtype = {
          package = lib.mkDefault pkgs.voxtype-vulkan;
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
            output.paste_keys = "ctrl+shift+v";
            output.restore_clipboard = true;
            output.shift_enter_newlines = true;
            vad.enable = true;
          };
        };
      }
    )
  ];
}
