{ config, pkgs, ... }:

let
  hostname = "adam";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

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
      /home sns59.cs.princeton.edu(rw)
    '';
  };
  # Open TCP & UDP ports (2049 + statdPort + lockdPort) for NFS server
  networking.firewall.allowedTCPPorts = [ 2049 111 4000 4001 ];
  networking.firewall.allowedUDPPorts = [ 2049 111 4000 4001 ];
}
