# Home Manager module using systemd user units for syncing and testing Bitwarden secrets securely

{ config, lib, pkgs, ... }:

let
  user = "cjshearer";
  testCredentialName = "test-credential";
  testServiceName = "test-cat.service";
  sneakyServiceName = "sneaky-cat.service";
  bitwardenItem = "test-secret";
in
{
  # home-manager.users.cjshearer.systemd.user.services = {
  #   sync-test-credential = {
  #     Unit = {
  #       Description = "Fetch and encrypt test-secret from Bitwarden";
  #       After = [ "network-online.target" ];
  #     };

  #     Service = {
  #       Type = "oneshot";
  #       ExecStart = lib.getExe (pkgs.writeShellApplication {
  #         name = "sync-test-secret";

  #         runtimeInputs = [ pkgs.rbw pkgs.systemd pkgs.coreutils ];

  #         text = ''
  #           set -euo pipefail

  #           mkdir -p "$HOME/.local/share/credentials"
  #           chmod 700 "$HOME/.local/share/credentials"

  #           secret="$(rbw get ${lib.escapeShellArg bitwardenItem})"

  #           cred_file="$HOME/.local/share/credentials/${testServiceName}-${testCredentialName}.cred"';

  #           echo -n "$secret" | systemd-creds encrypt \
  #             --user \
  #             --name=${testCredentialName} \
  #             ${testServiceName} > "$cred_file"

  #           chmod 0600 "$cred_file"
  #         '';

  #       });
  #     };

  #     Install = {
  #       WantedBy = [ "default.target" ];
  #     };
  #   };


  #   ${testServiceName} = {
  #     Unit = {
  #       Description = "Print Bitwarden secret from secure credential";
  #     };

  #     Service = {
  #       Type = "oneshot";
  #       LoadCredentialEncrypted = [
  #         "${testCredentialName}:%h/.local/share/credentials/${testServiceName}-${testCredentialName}.cred"
  #       ];
  #       ExecStart = pkgs.writeShellScript "cat-secret" ''
  #         echo "✅ test-cat can access:"
  #         cat "$CREDENTIALS_DIRECTORY/${testCredentialName}"
  #       '';
  #     };

  #     Install = {
  #       WantedBy = [ "default.target" ];
  #     };
  #   };

  #   ${sneakyServiceName} = {
  #     Unit = {
  #       Description = "👀 Try to steal Bitwarden credential";
  #     };

  #     Service = {
  #       Type = "oneshot";
  #       LoadCredentialEncrypted = [
  #         "${testCredentialName}:%h/.local/share/credentials/${testServiceName}-${testCredentialName}.cred"
  #       ];
  #       ExecStart = pkgs.writeShellScript "fail-to-cat-secret" ''
  #         echo "🚨 sneaky-cat attempting access:"
  #         cat "$CREDENTIALS_DIRECTORY/${testCredentialName}" || echo "❌ Access denied"
  #       '';
  #     };

  #     Install = {
  #       WantedBy = [ "default.target" ];
  #     };
  #   };
  # };
} 
