{ config, pkgs, ... }:

let
  hostname = "sns61";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configuration for all machines (locale, SSHd,
  # updates...)
  imports = [ common ];

  users.mutableUsers = false;

  users.users.leons = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "lschuermann";
  };
}
