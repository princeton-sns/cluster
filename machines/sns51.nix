{ config, pkgs, ... }:

let
  hostname = "sns51";
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

  # For Leopard caching project
  users.users.theano = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "theanoli";
  };

  users.users.nkaas = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "nickaashoek";
  };

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };
}
