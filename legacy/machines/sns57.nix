# @theanoli using to run simulations that require lots of memory.

{ config, pkgs, ... }:

let
  hostname = "sns57";
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
  
  services.openssh.forwardX11 = true;

  users.users.theano = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "theanoli";
  };
}
