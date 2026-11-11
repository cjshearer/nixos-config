{
  buildGoModule,
  lib,
}:
buildGoModule {
  pname = "syncthing-config";
  version = "0.1.0";

  src = ./.;
  vendorHash = null;

  meta = {
    description = "Deterministic Syncthing identity and mesh configuration";
    mainProgram = "syncthing-config";
    license = lib.licenses.mit;
  };
}
