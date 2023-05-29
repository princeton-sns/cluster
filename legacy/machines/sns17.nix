# Collective is an OIT hosted VM that @alevy "owns"
{ config, pkgs, ... }:

let
  hostname = "sns17";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ ../utils/deplorable.nix common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
  ];

  programs.mosh.enable = true;

  networking.firewall.allowedTCPPorts = [
    # NGINX
    80 443
  ];

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
      repos = {
        "systems" = {
          repo = "PrincetonSystems/www";
          reference = "refs/heads/master";
          out = "princeton.systems";
        };
      };
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."cos316.princeton.edu" = {
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
        proxyPass = "http://127.0.0.1:1337/cos316";
      };
    };
    virtualHosts."cos561.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/home/rnetravali/public_html/cos561";
    };
    virtualHosts."ml-video-seminar.princeton.systems" = {
      forceSSL = true;
      enableACME = true;
      root = "/home/rnetravali/public_html/cos561";
    };
  };

  security.acme = {
    defaults.email = "aalevy@princeton.edu";
    acceptTerms = true;
  };

  users.users.alevy = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = utils.githubSSHKeys "alevy";
  };

  users.users.rnetravali = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = utils.githubSSHKeys "ravinet";
  };
}
