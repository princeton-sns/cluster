{ config, pkgs, ... }:

let
  hostname = "adam";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ../utils/deplorable.nix ../utils/matrix.nix ];

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

  systemd.services.nginx.serviceConfig.ProtectHome = "read-only";

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
