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
