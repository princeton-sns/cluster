{ config, pkgs, ... }:

let
  hostname = "adam";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
  deplorable = { config, lib, pkgs, ... }:
    with lib;

    let

      cfg = config.services.deplorable;
      deplorablePkg = import (pkgs.fetchFromGitHub {
        owner = "alevy";
        repo = "deplorable";
        rev = "c2bb62a5bf5719964e21ebc7a66f2e56ad8a1533";
        sha256 = "0b096074y6c7xk3vspsi8f5bkk7fk9q88gvsw1q5k1v52x1nl3hy";
      }) {};
      configFile = pkgs.writeText "config.yaml" (builtins.toJSON cfg.config);
    in

    {
      options = {
        services.deplorable = {
          enable = mkEnableOption "Deplorable";
          port = mkOption {
            type = types.port;
            default = 1337;
            example = 1337;
            description = ''
              TCP port to listen for incoming connections.
            '';
          };
          listenAddress = mkOption {
            type = types.str;
            default = "0.0.0.0";
            example = "0.0.0.0";
            description = ''
              Address to listen for incoming connections.
            '';
          };
          openFirewall = mkOption {
            type = types.bool;
            default = false;
          };
          config = mkOption {
            type = types.attrs;
            default = {
              repos = {};
            };
          };
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [ deplorablePkg ];
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

        systemd.services.deplorable = {
          wantedBy = [ "multi-user.target" ]; 
          after = [ "network.target" ];
          description = "Deplorable service";
          path = [ pkgs.nix pkgs.gnutar pkgs.gzip ];
          environment = {
            XDG_CACHE_HOME = "/var/cache/deplorable";
            NIX_PATH = concatStringsSep ":" [
              "/nix/var/nix/profiles/per-user/root/channels/nixos"
              "nixos-config=/etc/nixos/configuration.nix"
              "/nix/var/nix/profiles/per-user/root/channels"
            ];
          };
          serviceConfig = {
            User = "deplorable";
            ExecStart = "${deplorablePkg}/bin/deplorable -l ${cfg.listenAddress}:${toString cfg.port} -c ${configFile}";
            Restart = "on-failure";
            PrivateTmp = true;
            StateDirectory = [ "deplorable" ];
            WorkingDirectory = [ "/var/lib/deplorable"];
            CacheDirectory = [ "deplorable" ];
          };
        };

        users.users = {
          deplorable = {
            isSystemUser = true;
            group = "deplorable";
          };
        };

        users.groups = {
          deplorable = {};
        };
      };
    };
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ deplorable common ./matrix.nix ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
  ];

  programs.mosh.enable = true;

  services.nfs.server = {
    enable = true;
    statdPort = 4000;
    lockdPort = 4001;
    exports = ''
      /home 128.112.7.0/24(rw)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 
    # NGINX
    80 443
    # Open TCP & UDP ports (2049 + statdPort + lockdPort) for NFS server
    2049 111 4000 4001
  ];
  networking.firewall.allowedUDPPorts = [ 2049 111 4000 4001 ];

  services.deplorable = {
    enable = true;
    config = {
      repos = {
        "sns" = {
          repo = "princeton-sns/www";
          reference = "refs/heads/master";
          out = "sns.cs.princeton.edu";
        };
      };
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."sns.cs.princeton.edu" = {
      serverAliases = [ "www.sns.cs.princeton.edu" ];
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/sns.cs.princeton.edu";
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/sns";
      };
    };
  };

  security.acme = {
    defaults.email = "aalevy@cs.princeton.edu";
    acceptTerms = true;
  };

  users.users.alevy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "alevy";
  };

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };

}
