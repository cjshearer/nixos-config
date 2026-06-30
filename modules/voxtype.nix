{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = lib.mkMerge [
    {
      home-manager.sharedModules = [
        (
          {
            lib,
            pkgs,
            config,
            osConfig,
            ...
          }:
          lib.mkIf config.services.voxtype.enable (
            lib.mkMerge [
              {
                # Voxtype needs WAYLAND_DISPLAY or DISPLAY to know which clipboard to interact with,
                # which session to monitor for hotkeys, and where emulated input events should be
                # sent.
                systemd.user.services.voxtype.Service.PassEnvironment = [
                  "DISPLAY"
                  "WAYLAND_DISPLAY"
                ];

                services.voxtype = {
                  package = lib.mkDefault pkgs.voxtype-vulkan;
                  loadModels = [ "base.en" ];
                  settings = {
                    audio.feedback.enabled = true;
                    meeting.enabled = true;
                    output.mode = lib.mkDefault "paste";
                    output.paste_keys = "ctrl+shift+v";
                    output.restore_clipboard = true;
                    output.shift_enter_newlines = true;
                    vad.enable = true;
                  };
                };
              }

              (lib.mkIf osConfig.wsl.enable {
                # WSL GPU access requires the D3D12/dxcore libraries from Windows to be on
                # LD_LIBRARY_PATH.
                systemd.user.services.voxtype.Service.Environment = [
                  "LD_LIBRARY_PATH=/usr/lib/wsl/lib"
                ];

                services.voxtype.settings = {
                  hotkey.enabled = false;
                  output.mode = "clipboard";
                };

                # By using both voxtype's clipboard mode and a systemd user service that monitors
                # for finished transcriptions, we can trigger a paste in Windows, simulating the
                # behavior of voxtype's paste mode without going to the trouble of finding some way
                # to make wtype work in WSLg.
                systemd.user.services.voxtype-wsl-paste-mode = {
                  Unit = {
                    Description = "VoxType state transition paste";
                    PartOf = [ "voxtype.service" ];
                    After = [ "voxtype.service" ];
                  };
                  Service = {
                    Type = "simple";
                    ExecStart = pkgs.writeShellScript "voxtype-state-paste" ''
                      set -eu

                      stateFile="''${XDG_RUNTIME_DIR:?}/voxtype/state"
                      stateDir="$(dirname "''${stateFile}")"

                      mkdir -p "''${stateDir}"

                      ${pkgs.inotify-tools}/bin/inotifywait -m -e create -e close_write --include '(^|.*/)state$' --format '%w%f' "''${stateDir}" | while read -r _; do
                        currentState="$(tr -d '\r\n' < "''${stateFile}")"

                        if [ "''${currentState}" = "idle" ]; then
                          /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command '
                            $wshell = New-Object -ComObject WScript.Shell
                            $wshell.SendKeys("^v")
                          ' >/dev/null 2>&1 || true
                        fi
                      done
                    '';
                    Restart = "always";
                    RestartSec = 1;
                  };
                  Install.WantedBy = [ "voxtype.service" ];
                };
              })
            ]
          )
        )
      ];
    }

    # The Windows-side push-to-talk hotkey and microphone sharing are system concerns, so they are
    # configured here for the WSL default user when they have voxtype enabled.
    (lib.mkIf
      (config.wsl.enable && config.home-manager.users.${config.wsl.defaultUser}.services.voxtype.enable)
      {
        # Use Scroll Lock as push-to-talk from Windows by calling voxtype in WSL.
        windows.files.voxtype = {
          source = pkgs.writeText "voxtype.ahk" ''
            #Requires AutoHotkey v2.0
            #SingleInstance Force
            #MaxThreadsPerHotkey 1
            SetScrollLockState "AlwaysOff"

            $*ScrollLock:: {
              Run "wsl.exe --distribution NixOS --exec /etc/profiles/per-user/${config.wsl.defaultUser}/bin/voxtype record start", , "Hide"

              KeyWait "ScrollLock"
              Run "wsl.exe --distribution NixOS --exec /etc/profiles/per-user/${config.wsl.defaultUser}/bin/voxtype record stop", , "Hide"
            }
          '';
          destination = "AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/voxtype.ahk";
        };

        # WSLg uses pulseaudio to share the microphone from Windows to WSL
        services.pulseaudio.enable = true;
      }
    )
  ];
}
