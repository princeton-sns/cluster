# @yuetan uses this machine as a testbed for securefaas project

{ config, pkgs, ... }:

let
  hostname = "sns44";
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

  # open up specified ports
  networking.firewall.allowedTCPPorts = [ 8888 ];

  programs.mosh.enable = true;

  virtualisation.docker.enable = true;

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
}
