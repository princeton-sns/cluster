{ config, pkgs, ... }:

let
  hostname = "adam";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ../utils/deplorable.nix ../utils/matrix.nix ../utils/matrix-slack.nix ];

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

  systemd.services.nginx.serviceConfig.ProtectHome = "read-only";

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
    virtualHosts."princeton.systems" = {
      serverAliases = [ "www.princeton.systems" ];
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/princeton.systems";
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/systems";
      };
    };
    virtualHosts."cos316.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/cos316";
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
    virtualHosts."cos561.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/home/rnetravali/public_html/COS561";
    };
    virtualHosts."ml-video-seminar.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/home/rnetravali/public_html/ml-video-seminar";
    };
    virtualHosts."praxis.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/lib/deplorable/praxis";
      basicAuthFile = "/var/lib/praxis-auth";
      locations."/.deplorable" = {
        proxyPass = "http://127.0.0.1:1337/praxis";
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

  users.users.rnetravali = {
    isNormalUser = true;
    homeMode = "755";
    openssh.authorizedKeys.keys = utils.githubSSHKeys "ravinet";
  };

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };

}
