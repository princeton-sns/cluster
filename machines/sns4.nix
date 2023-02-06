# Workstation to be used as a Hydra build machine for nix-litex:
# https://git.sr.ht/~lschuermann/nix-litex

{ config, pkgs, ... }:

let
  hostname = "sns4";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configuration for all machines (locale, SSHd, updates...)
  imports = [ common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim htop tmux nload iftop dnsutils gitAndTools.gitFull gnupg
    mtr bc zip unzip nmap nix-prefetch-git
  ];

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };
}
