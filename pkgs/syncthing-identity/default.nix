{
  buildGoModule,
  lib,
}:
buildGoModule {
  pname = "syncthing-identity";
  version = "0.1.0";

  src = ./.;
  vendorHash = null;

  meta = {
    description = "Deterministic Syncthing identity generator";
    mainProgram = "syncthing-identity";
    license = lib.licenses.mit;
  };
}
