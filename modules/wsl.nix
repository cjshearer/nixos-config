{
  pkgs,
  lib,
  config,
  nixos-wsl,
  ...
}:
{
  imports = [ nixos-wsl.nixosModules.default ];

  config = lib.mkIf config.wsl.enable {
    # Windows Terminal supports true color
    environment.sessionVariables.COLORTERM = "truecolor";

    # awaiting https://github.com/nix-community/NixOS-WSL/pull/970
    environment.systemPackages = [
      (
        let
          wl-copy = pkgs.writeShellScriptBin "wl-copy" ''
            printf '%s' "$(cat)" | ${pkgs.dos2unix}/bin/unix2dos | /mnt/c/windows/system32/clip.exe
          '';

          wl-paste = pkgs.writeShellScriptBin "wl-paste" ''
            /mnt/c/windows/system32/windowspowershell/v1.0/powershell.exe -command Get-Clipboard | ${pkgs.dos2unix}/bin/dos2unix
          '';
        in
        pkgs.symlinkJoin {
          name = "wl-clipboard-wsl";
          paths = [
            wl-copy
            wl-paste
          ];
        }
      )
    ];

    wsl.defaultUser = "cjshearer";
    # Including windows paths makes tab completion slow
    wsl.interop.includePath = false;
    wsl.interop.register = true;
    wsl.ssh-agent.enable = true;

    # TODO: use this to sync dotfiles to Windows:
    # https://github.com/swebra/dotfiles/blob/master/home-manager/windows/sync-windows-dotfiles.nix

    # .wslconfig
    # [wsl2]
    # networkingMode=Mirrored

    # FancyWM/settings.json
    # {
    #   "ActivationHotkey": "None_None",
    #   "ProcessIgnoreList": [
    #     "Taskmgr"
    #   ],
    #   "ShowFocus": true,
    #   "ShowStartupWindow": false,
    #   "SoundOnFailure": false,
    #   "WindowPadding": 0
    # }

    # fancy-wm.ahk
    # #Requires AutoHotkey v2.0.2
    # #SingleInstance Force
    # FancyWM(action) {
    #     RunWait(format("fancywm.exe --action {}", action), , "Hide")
    # }

    # ; Disables Windows key search box, but allows combinations
    # ~LWin::Send("{Blind}{vkE8}")
    # ~RWin::Send("{Blind}{vkE8}")

    # #q::Run("wt.exe")

    # #Left::FancyWM("MoveFocusLeft")
    # #Right::FancyWM("MoveFocusRight")
    # #Up::FancyWM("MoveFocusUp")
    # #Down::FancyWM("MoveFocusDown")
    # +#Left::FancyWM("SwapLeft")
    # +#Right::FancyWM("SwapRight")
    # +#Up::FancyWM("SwapUp")
    # +#Down::FancyWM("SwapDown")
  };
}
