{ config, pkgs, lib, ... }:

let
  snsHosts = [
    # alpha machines
    # beta machines
    "sns26" "sns29" "sns30" "sns31" "sns32" "sns33" "sns35" "sns38" "sns40"
    "sns41" "sns43" "sns44" "sns45" "sns46" "sns47" "sns49" "sns50" "sns51"
    "sns52" "sns54" "sns55" "sns57" "sns58"
    # gamma machines
    "sns62" "adam"
  ];

in
{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "3276fa8f";
    hostName = "adam";

    interfaces."enp4s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.gamma = {
      enable = true;

      bootDiskNode = "/dev/disk/by-id/wwn-0x5000c50064255757";
      bootPartUUID = "1114-977D";
      swapPartUUID = "c08fe64d-c45e-4767-953c-561210a714f1";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # ---------- ZFS Backup Server -----------------------------------------------

  fileSystems."/var/lib/syncoid" = {
    device = "/var/state/syncoid-home";
    fsType = "none";
    options = [ "bind" ];
  };

  services.syncoid = {
    enable = true;
    sshKey = "/var/lib/syncoid/.ssh/id_ed25519";
    commands = (let
      hostCommand = hostname: {
        # Created beforehand using:
        # zfs create -o mountpoint=none -o compression=lz4 rpool/cluster-backups
        target = "rpool/cluster-backups/${hostname}";
        source = "backup-ssh@${hostname}.cs.princeton.edu:rpool/state";
        recursive = true;
        extraArgs = [ "--keep-sync-snap" ];
      };
    in
      lib.genAttrs snsHosts hostCommand) // {
        # Special backup target for ssdpool0 on SNS26, holding Matrix synapse DB
        sns26-ssdpool0 = {
          target = "rpool/cluster-backups/sns26-ssdpool0";
          source = "backup-ssh@sns26.cs.princeton.edu:ssdpool0/state";
          recursive = true;
          extraArgs = [ "--keep-sync-snap" ];
        };
      };
  };

  # Augment the zfs-snap-prune service (defined in the shared cluster config)
  # by also pruning backup snapshots.
  services.zfs-snap-prune.jobs = [ {
    label = "SNS cluster backups prune";
    pool = "rpool";
    dataset = "/cluster-backups";
    recursive = true;
    snapshot_pattern = "^syncoid_sns26_(.*)$";
    snapshot_time = {
      source = "capture_group";
      capture_group = 1;
      format = "chrono_fmt";
      chrono_fmt = "%Y-%m-%d:%H:%M:%S-GMT%:z";
    };
    retention_policy = "simple_buckets";
    retention_config = {
      latest = 1;
      hourly = 5;
      daily = 7;
    };
  } ];

  # ---------- Prometheus Monitoring Server ------------------------------------

  fileSystems."/var/lib/prometheus" = {
    device = "rpool/state/prometheus-state";
    fsType = "zfs";
  };

  services.prometheus = {
    enable = true;
    stateDir = "prometheus";
    webExternalUrl = "http://adam.cs.princeton.edu:${
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

  # ---------- NGINX Web Server ------------------------------------------------

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx.enable = true;

  # Only recommendedProxySettings and recommendedGzipSettings are
  # strictly required, but the rest make sense as well:
  services.nginx.recommendedTlsSettings = true;
  services.nginx.recommendedOptimisation = true;
  services.nginx.recommendedGzipSettings = true;
  services.nginx.recommendedProxySettings = true;

  services.nginx.virtualHosts.${config.networking.fqdn} = {
    enableACME = true;
    addSSL = true;
    locations."/".extraConfig = ''
      return 404;
    '';
  };

  security.acme = {
    defaults.email = "aalevy@princeton.edu";
    acceptTerms = true;
  };

  fileSystems."/var/lib/acme" = {
    device = "rpool/state/acme-state";
    fsType = "zfs";
  };
}

