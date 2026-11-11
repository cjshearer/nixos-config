# File sets
#
# A file set is a named directory whose contents are replicated across hosts and, optionally, to
# a cloud counterpart.
#
# Membership and ownership
# ------------------------
# A host becomes a member of a set with `enable`. Members keep the set locally and participate in
# peer synchronization.
#
# One member may own the set with `owner`. An owner replicates the set to its cloud counterpart
# when one is configured, and resolves conflict copies. An owner without a cloud counterpart
# merges conflict copies and does not replicate. `owner` implies `enable`.
#
# Configuration
# -------------
#   enable              this host is a member of the set (default false)
#   path                local directory
#   remote              cloud counterpart (default null)
#   sync.enable         peer synchronization (default false)
#   sync.ignore         paths peer synchronization ignores
#   owner               this member owns the set (default false)
#   replicate.interval  period between replication runs (default null; set by the declaring
#                       module for a set without peer synchronization)
#   exclude             additional paths replication omits
#
# Acquisition
# -----------
# A member acquires the set once, when it first holds an empty tree, from:
#
#   1. a member that already holds the set
#   2. the cloud counterpart, when one is configured
#   3. the empty directory
#
# After acquisition, an empty tree is an intentional state. A member's copy takes precedence over
# the cloud counterpart. Acquisition does not change ownership.
#
# Peer synchronization
# --------------------
# The declaring module enables peer synchronization for sets shared across hosts. Members exchange
# changes directly and converge. A set without peer synchronization has only the owner and the
# cloud counterpart.
#
# Consistency
# -----------
# The system is eventually consistent: when edits stop and the owner is available, all members
# converge to the same tree and the cloud counterpart follows the owner's replicated tree.
#
# Conflict resolution
# -------------------
# Peer synchronization retains both sides of a concurrent change as a conflict copy. The owner
# retains previous versions to provide a common ancestor, resolves conflict copies in plaintext
# files, and leaves other files unchanged. A conflict that cannot be resolved cleanly remains a
# conflict copy. A merge produces a complete replacement or leaves the original unchanged, and an
# interrupted merge can be retried safely.
#
# Replication
# -----------
# An owner replicates one-way to the cloud counterpart. After acquisition, the owner's tree is
# authoritative, including deletions.
#
# With peer synchronization enabled, the owner resolves conflict copies before replicating a
# settled set.
#
# With peer synchronization disabled, the declaring module sets `replicate.interval` and
# replication runs at that period.
#
# A host may replicate different sets concurrently. Each set runs one replication at a time.
#
# Exclusions
# ----------
# Peer synchronization ignores and replication excludes are independent. Replication omits
# transport state and unresolved conflict copies, in addition to `exclude`.
#
# Invariants
# ----------
# - A set may have one owner.
# - An owner replicates when the set has a cloud counterpart.
# - The declaring module sets `replicate.interval` for a set without peer synchronization.
{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.users.cjshearer.files;

  setOf = host: name: host.config.users.cjshearer.files.${name} or null;

  ownerCount =
    name:
    lib.count (host: (setOf host name) != null && (setOf host name).owner) (
      lib.attrValues self.nixosConfigurations
    );

  peersOf =
    name:
    lib.attrNames (
      lib.filterAttrs (
        _: host:
        let
          set = setOf host name;
        in
        set != null && (set.enable || set.owner) && set.sync.enable
      ) self.nixosConfigurations
    );

  syncedSets = lib.filterAttrs (_: set: set.sync.enable) cfg;
in
{
  options.users.cjshearer.files = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options = {
            enable = lib.mkEnableOption "holding this file set";

            path = lib.mkOption {
              type = lib.types.str;
              description = "Local directory for the set.";
            };

            remote = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Cloud counterpart for the set.";
            };

            sync = {
              enable = lib.mkEnableOption "peer synchronization for this file set";

              ignore = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Paths peer synchronization ignores.";
              };
            };

            owner = lib.mkEnableOption "owning this file set";

            replicate.interval = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Period between replication runs for a set without peer synchronization.";
            };

            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Additional paths replication omits.";
            };
          };

          config.enable = lib.mkDefault config.owner;
        }
      )
    );
    default = { };
  };

  config = {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: set: [
        {
          assertion = ownerCount name <= 1;
          message = "users.cjshearer.files.${name}: at most one host may be the owner.";
        }
        {
          assertion = !set.owner || set.enable;
          message = "users.cjshearer.files.${name}: owner requires enable.";
        }
        {
          assertion = !set.sync.enable || set.replicate.interval == null;
          message = "users.cjshearer.files.${name}: replicate.interval applies only without peer synchronization.";
        }
        {
          assertion = set.replicate.interval == null || set.remote != null;
          message = "users.cjshearer.files.${name}: replicate.interval requires a remote.";
        }
        {
          assertion =
            !(set.owner && set.remote != null && !set.sync.enable) || set.replicate.interval != null;
          message = "users.cjshearer.files.${name}: a non-peer owner with a remote requires replicate.interval.";
        }
      ]) cfg
    );

    services.syncthing.settings.folders = lib.mapAttrs' (
      name: set:
      lib.nameValuePair name (
        {
          label = name;
          path = set.path;
          devices = [ ];
          ignorePatterns = set.sync.ignore;
        }
        // lib.optionalAttrs set.owner {
          versioning.type = "staggered";
        }
      )
    ) syncedSets;

    users.cjshearer.services.syncthing.folderDevices = lib.mapAttrs (name: _: peersOf name) syncedSets;
  };
}
