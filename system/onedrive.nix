{ lib, config, ... }: lib.mkIf config.services.onedrive.enable { }
# TODO: replace with restic/rclone
