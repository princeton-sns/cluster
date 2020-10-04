{ config, pkgs, ... }:

let
  utils = import ./utils.nix;
in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    curl wget ipmitool vim git
  ];

  programs.mosh.enable = true;

  virtualisation.docker.enable = true;

  users.users.alevy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "alevy";
  };
}
