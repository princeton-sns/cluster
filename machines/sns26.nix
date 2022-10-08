{ config, pkgs, ... }:

let
  hostname = "sns26";
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

  networking.firewall.allowedTCPPorts = [
    # Frida server
    8000
  ];

  virtualisation.docker.enable = true;

  users.users.npopescu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "nataliepopescu";
  };
}
