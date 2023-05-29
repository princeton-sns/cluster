# @davidhliu uses this machine as a workstation

{ config, pkgs, ... }:

let
  hostname = "sns52";
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

  virtualisation.docker.enable = true;

  users.users.davidhliu= {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "LedgeDash";
  };
  
  users.users.neilagarwal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker"];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "neilsagarwal";
  };
  
  users.users.ruipan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker"];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "ruipeterpan";
  };

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };
}
