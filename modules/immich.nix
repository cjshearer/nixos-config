{
  lib,
  config,
  ...
}:
lib.mkIf config.services.immich.enable {

}
