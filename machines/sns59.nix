{ config, pkgs, ... }:

let
  hostname = "sns59";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    lkl lmdb python39Full e2fsprogs gnumake wget
    vim tmux
  ];

  programs.mosh.enable = true;

  services.openssh.forwardX11 = true;

  fileSystems."/nfs/home" = {
    device = "adam-new.cs.princeton.edu:/home";
    fsType = "nfs4";
  };

  # Expose ports for Faasten gateway
  networking.firewall.interfaces."enp7s0".allowedTCPPorts = [
    # 8080 for requests, 1337 for RPCs
    8080 1337
  ];

  # Using this machine for flash caching project (Orca). Added Sept. 2021.
  users.users.nkaas = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "nickaashoek";
  };

  users.users.theano = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "theanoli";
  };

  # For Faasten experiments
  users.users.yuetan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "tan-yue";
  };

  users.users.alevy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "alevy";
  };

  users.users.cherrypiejam = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "cherrypiejam";
  };

  users.users.npopescu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "nataliepopescu";
  };
}
