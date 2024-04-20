{ lib, config, ... }: lib.mkIf config.programs.google-chrome.enable { }
