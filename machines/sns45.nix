{ config, pkgs, lib, ... }: let

  githubSSHKeys = user:
    builtins.map (record: record.key) (
      builtins.fromJSON (
        builtins.readFile (
          builtins.fetchurl "https://api.github.com/users/${user}/keys")));

in {
  imports = [
    ../sns-cluster
    ../utils/deplorable.nix
  ];

  networking = {
    hostId = "18e30b23";
    hostName = "sns45";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25abfe404";
        partUUID = "BFC9-B709";
      } ];
      swapPartUUIDs = [ "43729736-39c3-4895-abc2-bb7f698b0d96" ];
    };
  };

  # ---------- Web Server ------------------------------------------------------

  networking.firewall.allowedTCPPorts = [
    # NGINX
    80 443
  ];

  security.acme = {
    defaults.email = "aalevy@cs.princeton.edu";
    acceptTerms = true;
  };

  fileSystems."/var/lib/acme" = {
    device = "rpool/state/acme-state";
    fsType = "zfs";
  };

  services.deplorable = {
    enable = true;
    config = {
      repos = {
        "sns" = {
          repo = "princeton-sns/www";
          reference = "refs/heads/master";
          out = "sns.cs.princeton.edu";
        };
        "systems" = {
          repo = "PrincetonSystems/www";
          reference = "refs/heads/master";
          out = "princeton.systems";
        };
        "cos316" = {
          repo = "cos316/cos316-web";
          reference = "refs/heads/master";
          out = "cos316";
        };
        "cos316-f22" = {
          repo = "cos316/cos316-web";
          reference = "refs/tags/f22";
          out = "cos316-f22";
        };
        "os-seminar" = {
          repo = "princetonsystems/os-seminar";
          reference = "refs/heads/main";
          out = "os-seminar";
        };
        "praxis" = {
          repo = "princeton-sns/ideation_station";
          reference = "refs/heads/main";
          out = "praxis";
        };
      };
    };
  };

  services.nginx = {
    enable = true;

    # Declarative sites deployed through `deplorable`:

    virtualHosts."sns.cs.princeton.edu" = {
      serverAliases = [ "www.sns.cs.princeton.edu" ];
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/sns.cs.princeton.edu";
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/sns";
      };
    };

    virtualHosts."princeton.systems" = let
      matrixServerFQDN = "matrix.princeton.systems";
    in {
      serverAliases = [ "www.princeton.systems" ];
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/princeton.systems";

      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/systems";
      };

      locations."= /.well-known/matrix/server".extraConfig =
        let
          # use 443 instead of the default 8448 port to unite
          # the client-server and server-server port for simplicity
          server = { "m.server" = "${matrixServerFQDN}:443"; };
        in ''
          add_header Content-Type application/json;
          return 200 '${builtins.toJSON server}';
        '';

      locations."= /.well-known/matrix/client".extraConfig =
        let
          client = {
            "m.homeserver" =  { "base_url" = "https://${matrixServerFQDN}"; };
            "m.identity_server" =  { "base_url" = "https://vector.im"; };
          };
        # ACAO required to allow riot-web on any URL to request this json file
        in ''
          add_header Content-Type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON client}';
        '';
    };

    virtualHosts."cos316.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/cos316";
      locations."/f22/" = {
        root = "/var/lib/deplorable/cos316-f22";
      };
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/cos316";
      };
    };

    virtualHosts."os-seminar.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/os-seminar";
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/os-seminar";
      };
    };

    virtualHosts."praxis.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/praxis";
      basicAuthFile = "/var/lib/praxis-basic-auth";
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/praxis";
      };
    };

    # Stateful sites:

    # Each site lives on a ZFS file system to not bind it to any single user's
    # home directory, avoid having the web server have access to home
    # directories, eventually support things such as quotas, different
    # compression levels, etc. This further automatically backs up sites as part
    # of the general ZFS state backups.
    #
    # To add a site:
    #
    # 1. Create the ZFS filesystem:
    #    `zfs create -o mountpoint=legacy rpool/state/www/$vhost`
    #    and set permissions accordingly.
    # 2. Add a virtualHost here.
    # 3. Add a mountpoint for /var/www/$vhost below.
    # 4. Profit.
    #
    # TODO: automate this eventually and provide a nicer interface, which takes
    # care of all required configuration. Maybe symlink sites into the user home
    # as well?

    virtualHosts."cos561.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/COS561";
    };

    virtualHosts."ml-video-seminar.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/ml-video-seminar";
    };
  };

  fileSystems."/var/www/COS561" = {
    device = "rpool/state/www/COS561";
    fsType = "zfs";
  };

  fileSystems."/var/www/ml-video-seminar" = {
    device = "rpool/state/www/ml-video-seminar";
    fsType = "zfs";
  };

  users.users.alevy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = githubSSHKeys "alevy";
  };

  users.users.rnetravali = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = githubSSHKeys "ravinet";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
