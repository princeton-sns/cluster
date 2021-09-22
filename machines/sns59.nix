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
  ];

  programs.mosh.enable = true;

  services.openssh.forwardX11 = true;

  fileSystems."/nfs/home" = {
    device = "adam-new.cs.princeton.edu:/home";
    fsType = "nfs4";
  };

  users.users.haoyu = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = utils.githubSSHKeys "Lei-Houjyu";
  };

  users.users.jiananl= {
    isNormalUser = true;
    openssh.authorizedKeys.keys = utils.githubSSHKeys "amberlu";
  };
  
  users.users.nkaas = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "nickaashoek";
  };

  users.users.alevy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "alevy";
  };

  users.users.theano = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "theanoli";
  };
}
