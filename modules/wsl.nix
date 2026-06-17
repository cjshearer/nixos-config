{
  pkgs,
  lib,
  config,
  nixos-wsl,
  ...
}:
{
  imports = [ nixos-wsl.nixosModules.default ];

  options.windows.files = lib.mkOption {
    type =
      with lib.types;
      attrsOf (submodule {
        options = {
          source = lib.mkOption {
            type = path;
            description = "Source path in the Nix store to copy to Windows.";
          };
          destination = lib.mkOption {
            type = str;
            description = "Destination path relative to the Windows user profile.";
          };
        };
      });
    default = { };
  };

  config = lib.mkIf config.wsl.enable {
    # Windows Terminal supports true color
    environment.sessionVariables.COLORTERM = "truecolor";

    # The standard clipboard now works between Windows and WSL. Used by zellij and voxtype
    environment.systemPackages = [ pkgs.wl-clipboard ];

    wsl.defaultUser = "cjshearer";
    # Including windows paths makes tab completion slow
    wsl.interop.includePath = false;
    wsl.interop.register = true;
    wsl.ssh-agent.enable = true;

    windows.files.wslconfig = {
      source = pkgs.writeText ".wslconfig" ''
        [wsl2]
        networkingMode=Mirrored
      '';
      destination = ".wslconfig";
    };

    system.activationScripts.syncWindowsFiles =
      let
        powershell = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
        files = lib.attrValues config.windows.files;
        formatCmd = fileCfg: ''
          ${lib.getExe pkgs.rsync} \
            -a --mkpath --copy-links --chmod=Da=rwx,Fa=r --checksum \
            ${lib.escapeShellArg (toString fileCfg.source)} "$windowsHome/${fileCfg.destination}"
        '';
      in
      ''
        windowsUser=$(${powershell} '$env:UserName' 2>/dev/null | tr -d $'\r\n')
        if [[ -z $windowsUser || ! -d /mnt/c/Users/$windowsUser ]]; then
          echo 'syncWindowsFiles: could not determine Windows user; skipping.'
        else
          windowsHome="/mnt/c/Users/$windowsUser"
          ${lib.strings.concatMapStrings formatCmd files}
        fi
      '';
  };
}
