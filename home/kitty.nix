{ lib, config, ... }: lib.mkIf config.programs.kitty.enable { }
