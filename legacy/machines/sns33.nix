# Configured as a workstation for @lei

{ config, pkgs, ... }:

let
  hostname = "sns33";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
  kubeMasterIP = "10.1.1.2";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 6443;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  services.kubernetes = {
    roles = ["master" "node"];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };

    # use coredns
    addons.dns.enable = true;
    
    # needed if you use swap
    kubelet.extraOpts = "--fail-swap-on=false";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git zip unzip
    vim tmux wget docker-compose kubectl kompose kubernetes helm
  ];

  programs.mosh.enable = true;

  virtualisation.docker.enable = true;

  users.mutableUsers = false;

  users.users.lei = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "geraldleizhang";
  };

  users.users.leochanj = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "leochanj105";
  };

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };
}
