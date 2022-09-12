# Configured as a workstation for @lschuermann

{ config, pkgs, ... }:

let
  hostname = "sns45";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim htop tmux nload iftop dnsutils gitAndTools.gitFull gnupg
    gitAndTools.git-annex mtr bc zip unzip nmap nix-prefetch-git pdftk
    imagemagick ghostscript rclone
  ];

  programs.mosh.enable = true;

  users.mutableUsers = false;

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOD4XspKe2E5BhBmx+GtRHdRR72+Q7wC7nFHbDj1VVzJ lschuermann/silicon/sns-nixbuild"
  ];
}
