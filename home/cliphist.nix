{ lib, config, ... }: lib.mkIf config.services.cliphist.enable {
  # TODO: set rules to automatically clear old history
}
