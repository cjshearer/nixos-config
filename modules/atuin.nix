{ lib, config, ... }:
{
  options.users.cjshearer.programs.atuin.enable = lib.mkEnableOption "atuin";

  config = lib.mkIf config.users.cjshearer.programs.atuin.enable {
    home-manager.users.cjshearer.programs.atuin = {
      enable = true;
    };
    home-manager.users.cjshearer.programs.bash.enable = true;

    home-manager.users.cjshearer.programs.bash.bashrcExtra = ''
      incognito () {
        if [[ $1 = disable ]] || [[ $1 == d ]]
        then
          # disable incognito
          if [[ -n "''${BLE_VERSION-}" ]]; then
            echo "no idea what ble is (no incognito mode available here)"
          else
            precmd_functions+=(_atuin_precmd)
            preexec_functions+=(_atuin_preexec)
          fi
        else
          # enable incognito
          if [[ -n "''${BLE_VERSION-}" ]]; then
            echo "no idea what ble is (no incognito mode available here)"
          else
            precmd_functions=("''${precmd_functions[@]/_atuin_precmd}")
            preexec_functions=("''${preexec_functions[@]/_atuin_preexec}")
          fi
        fi
      }
    '';
  };
}
