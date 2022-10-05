# Configured as a workstation for @lei

{ config, pkgs, ... }:

let
  hostname = "sns33";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim tmux wget
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
    openssh.authorizedKeys.keys = utils.githubSSHKeys "leochanj";
  };
}
