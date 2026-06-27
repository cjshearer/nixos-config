{
  home-manager.sharedModules = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        options.programs.orca-slicer.enable = lib.mkEnableOption "orca-slicer";
        options.programs.orca-slicer.package = lib.mkOption {
          type = lib.types.package;
          default = (
            let
              wxGTK' = (
                pkgs.wxwidgets_3_3.overrideAttrs (old: {
                  configureFlags = old.configureFlags ++ [
                    "--enable-debug=no"
                  ];
                })
              );
            in
            pkgs.orca-slicer.overrideAttrs (
              finalAttrs: previousAttrs: {
                version = "2.4.0-belt-printer";
                src = pkgs.fetchFromGitHub {
                  owner = "OrcaSlicer";
                  repo = "OrcaSlicer";
                  rev = "5428a0715d1379515b7047d7893f9624ccba7293";
                  hash = "sha256-qvSccuQSiYbToz+CeDj4j6v0+V6CgQfcXH2dqc9682o=";
                };
                patches = builtins.filter (
                  # I don't mind the update check enough to make it work with this branch
                  p: (p.name or "") != "pr-7650-configurable-update-check.patch"
                ) previousAttrs.patches;
                buildInputs = map (
                  p:
                  if (p.pname or "") == "eigen" then
                    pkgs.eigen_5
                  else if (p.pname or "") == "wxwidgets" then
                    wxGTK'
                  else
                    p
                ) previousAttrs.buildInputs;
                nativeBuildInputs = map (
                  p: if (p.pname or "") == "wxwidgets" then wxGTK' else p
                ) previousAttrs.nativeBuildInputs;
              }
            )
          );
        };

        config = lib.mkIf config.programs.orca-slicer.enable {
          home.packages = [ config.programs.orca-slicer.package ];
        };
      }
    )
  ];
}
