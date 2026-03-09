{
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

    wsl.defaultUser = "cjshearer";
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
