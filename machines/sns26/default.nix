{ config, pkgs, lib, ... }:

let
  snsHosts = [
    # alpha machines
    # beta machines
    "sns26" "sns29" "sns30" "sns31" "sns32" "sns33" "sns35" "sns38" "sns40"
    "sns41" "sns43" "sns44" "sns45" "sns46" "sns47" "sns49" "sns50" "sns51"
    "sns52" "sns54" "sns55" "sns57" "sns58"
    # gamma machines
    "sns62"
  ];

in
{
  imports = [
    ../../sns-cluster

    ./sns-matrix-synapse.nix
    ./sns-matrix-slack.nix

    ./tock-matrix-synapse.nix
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

  # Allow the backup user to access the `ssdpool0/state` ZFS datasets
  # as well:
  system.activationScripts."backup-ssh-zfs-ssdpool0-permissions" = {
    deps = [ "users" "groups" ];
    text = ''
      ${pkgs.zfs}/bin/zfs allow backup-ssh bookmark,hold,send,snapshot,mount,destroy ssdpool0/state
    '';
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
      sns26-ssdpool0 = {
        target = "rpool/cluster-backups/sns26-ssdpool0";
        source = "backup-ssh@sns26.cs.princeton.edu:ssdpool0/state";
        recursive = true;
        extraArgs = [ "--keep-sync-snap" ];
      };
    };
  };

  systemd.services = builtins.listToAttrs (builtins.map (h: lib.nameValuePair "syncoid-${h}" {
    serviceConfig = {
      ExecStartPre = lib.mkBefore [
	"-+${pkgs.zfs}/bin/zfs create -o mountpoint=none rpool/cluster-backups/${h}"
      ];
    };
  }) snsHosts);

  # Augment the zfs-snap-prune service by also pruning backup snapshots, and
  # snapshots of the ssdpool0:
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
  } {
    label = "Local ssdpool0 state";
    pool = "ssdpool0";
    dataset = "/state";
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

  # ---------- Shared SSD-backed PostgreSQL server -----------------------------

  services.postgresql.enable = true;

  fileSystems."/var/lib/postgresql" = {
    device = "ssdpool0/state/postgresql";
    fsType = "zfs";
  };

  # ---------- Send-only Postfix Server ----------------------------------------
  services.postfix = {
    enable = true;
    sslCert = config.security.acme.certs.${config.networking.fqdn}.directory + "/full.pem";
    sslKey = config.security.acme.certs.${config.networking.fqdn}.directory + "/key.pem";
    hostname = config.networking.fqdn;
    config = {
      inet_interfaces = "loopback-only";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
