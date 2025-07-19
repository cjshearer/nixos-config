{ lib, config, pkgs, ... }: {
  options.users.cjshearer.programs.rbw.enable = lib.mkEnableOption "rbw";
  # options.users.cjshearer.programs.rbw.secrets = lib.mkOption {
  #   type = lib.types.attrsOf (lib.types.submodule {
  #     options = {
  #       secret = lib.mkOption {
  #         type = lib.types.str;
  #         description = "Bitwarden secret name to fetch using `rbw get <secret>`.";
  #       };
  #       field = lib.mkOption {
  #         type = lib.types.str;
  #         description = "Field name within the Bitwarden item to fetch.";
  #         default = "password";
  #       };
  #       unit = lib.mkOption {
  #         type = lib.types.str;
  #         description = "The target systemd unit that will receive this secret.";
  #       };
  #       credentialName = lib.mkOption {
  #         type = lib.types.str;
  #         description = "The credential file name passed to LoadCredentialEncrypted=.";
  #       };
  #     };
  #   });
  #   description = "Mapping of secrets to fetch from Bitwarden and inject into systemd units securely.";
  #   default = { };
  # };

  config = lib.mkIf config.users.cjshearer.programs.rbw.enable {
    home-manager.users.cjshearer.programs.rbw = {
      enable = true;
      settings.email = "cjshearer@live.com";
      settings.pinentry = pkgs.pinentry;
      #pkgs.pinentry-tty;
      # settings.pinentry = "${pkgs.systemd}/bin/systemd-ask-password"; #pkgs.pinentry-tty;
    };

    # systemd.tmpfiles.rules = [
    #   "d /run/bitwarden/secrets 0700 root root -"
    # ];
  };
}

# # NixOS module that syncs secrets from Bitwarden using `rbw` and injects them into
# # systemd units securely using `systemd-creds`, with no on-disk passphrase storage.

# { config, lib, pkgs, ... }:

# let
#   inherit (lib) types mkOption mkIf mkMerge mapAttrsToList escapeShellArg;
# in
# {
#   options.bitwarden.secrets = mkOption {
#     type = types.attrsOf (types.submodule {
#       options = {
#         bitwardenItem = mkOption {
#           type = types.str;
#           description = "Bitwarden item name to fetch using `rbw get`.";
#         };

#         unit = mkOption {
#           type = types.str;
#           description = "The target systemd unit that will receive this secret.";
#         };

#         credentialName = mkOption {
#           type = types.str;
#           description = "The credential file name passed to LoadCredentialEncrypted=.";
#         };
#       };
#     });
#     description = "Mapping of secrets to fetch from Bitwarden and inject into systemd units securely.";
#     default = { };
#   };

#   config = mkIf (config.bitwarden.secrets != { }) {
#     environment.systemPackages = [ pkgs.rbw pkgs.systemd ];

#     systemd.tmpfiles.rules = [
#       "d /etc/credentials 0700 root root -"
#     ];

#     systemd.services.sync-bitwarden-secrets = {
#       description = "Sync Bitwarden secrets using rbw and encrypt them for systemd units";
#       wantedBy = [ "multi-user.target" ];
#       after = [ "network-online.target" ];
#       serviceConfig = {
#         Type = "oneshot";
#         ExecStart = pkgs.writeShellScript "sync-bitwarden-secrets" ''
#           set -euo pipefail
#           passphrase=$(systemd-ask-password "Bitwarden passphrase:")
#           RBW_SESSION="$(${pkgs.rbw}/bin/rbw unlock --raw <<< "$passphrase")"
#           unset passphrase

#           ${lib.concatStringsSep "\n" (mapAttrsToList (name: cfg: ''
#           secret="$(${pkgs.rbw}/bin/rbw get ${escapeShellArg cfg.bitwardenItem})"
#           echo -n "$secret" | ${pkgs.systemd}/bin/systemd-creds encrypt \
#             --with-key=yes --uid=0 --name=${escapeShellArg cfg.credentialName} ${escapeShellArg cfg.unit} \
#             > /etc/credentials/${cfg.unit}-${cfg.credentialName}.cred
#           chmod 0600 /etc/credentials/${cfg.unit}-${cfg.credentialName}.cred
#                     '') config.bitwarden.secrets)}
#         '';
#       };
#     };

#     systemd.services = mkMerge (mapAttrsToList
#       (name: cfg: {
#         ${cfg.unit} = {
#           serviceConfig.LoadCredentialEncrypted = [
#             "${cfg.credentialName}:/etc/credentials/${cfg.unit}-${cfg.credentialName}.cred"
#           ];
#         };
#       })
#       config.bitwarden.secrets);
#   };
# }
