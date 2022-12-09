# Configured as a workstation for @lschuermann to execute Vivado
# builds on.
#
# Vivado is installed through a release evaluation of
# https://github.com/lschuermann/tock-litex and adding the resulting
# derivation as a GC root (/nix/var/nix/gcroots/custom/). The actual
# Vivado package needs to be added to the Nix store as documented in
# "Adding files to the store" of https://nixos.wiki/wiki/Cheatsheet.

{ config, pkgs, ... }:

let
  hostname = "sns62";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configuration for all machines (locale, SSHd,
  # updates...)
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

  users.users.noiseeval = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = (
      lib.flatten (
        builtins.map utils.githubSSHKeys [
          "alevy"
          "lschuermann"
          "leochanj105"
        ]
      )
    ) ++ [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBrOyN+OmWSv0/RYd7jK+TKx4tMO5Fuz8wyaMUR+j6A noise-eval-peer-key"
    ];
  };
}
