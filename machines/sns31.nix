# Configured as a workstation for Jianan 
# Current project users include Jianan, and Haoyu. 

{ config, pkgs, ... }:

let
  hostname = "sns31";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];

  programs.mosh.enable = true;

  users.users.haoyu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "Lei-Houjyu";
  };

  users.users.jiananl= {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "amberlu";
  };
  
  users.users.araina= {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "ashwiniraina";
  };
}
