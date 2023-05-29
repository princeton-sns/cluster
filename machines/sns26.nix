{ config, pkgs, lib, ... }:

let
  snsHosts = [
    # alpha machines
    # beta machines
    "sns26" "sns29" "sns30" "sns31" "sns32" "sns33" "sns35" "sns38" "sns40"
    "sns41" "sns43" "sns44" "sns45" "sns46" "sns47" "sns50" "sns51" "sns52"
    "sns54" "sns55" "sns57" "sns58" "sns62"
    # gamma machines
    "sns62"
  ];

in
{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "90591947";
    hostName = "sns26";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/ata-WDC_WD1003FBYX-01Y7B0_WD-WCAW30746204";
        partUUID = "6C32-5AFA";
      } {
        diskNode = "/dev/disk/by-id/ata-WDC_WD1003FBYX-01Y7B0_WD-WCAW30858349";
        partUUID = "A9E0-4E85";
      } ];

      swapPartUUIDs = [
        "9463b40d-f607-416c-af0c-d95c9ff1eb6f"
        "f73cb467-270f-405a-a406-3d64808b68b8"
      ];
    };
  };

  # ---------- ZFS Backup Server -----------------------------------------------

  fileSystems."/var/lib/syncoid" = {
    device = "/var/state/syncoid-home";
    fsType = "none";
    options = [ "bind" ];
  };

  services.syncoid = {
    enable = true;
    sshKey = "/var/lib/syncoid/.ssh/id_ed25519";
    commands = let
      hostCommand = hostname: {
        # Created beforehand using:
        # zfs create -o mountpoint=none -o compression=lz4 rpool/cluster-backups
        target = "rpool/cluster-backups/${hostname}";
        source = "backup-ssh@${hostname}.cs.princeton.edu:rpool/state";
        recursive = true;
        extraArgs = [ "--keep-sync-snap" ];
      };
    in
      lib.genAttrs snsHosts hostCommand;
  };

  # ---------- Prometheus Monitoring Server ------------------------------------

  fileSystems."/var/lib/prometheus" = {
    device = "rpool/state/prometheus-state";
    fsType = "zfs";
  };

  services.prometheus = {
    enable = true;
    stateDir = "prometheus";
    webExternalUrl = "http://sns26.cs.princeton.edu:${
      toString config.services.prometheus.port}/";

    scrapeConfigs = [ {
      job_name = "cluster_node";
      scheme = "http";
      metrics_path = "/metrics";
      static_configs = [ {
        targets =
          builtins.map
            (hostname: "${hostname}.cs.princeton.edu:9100")
            snsHosts;
      } ];
    } ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
