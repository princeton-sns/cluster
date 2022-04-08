# Configured as a workstation for @cyu
# Can be taken back at the end of Spring '22 semester (note from 04/08/2022)

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
  ];

  programs.mosh.enable = true;

  users.mutableUsers = false;

  users.users.cyu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "cyu6";
  };
}
