{ config, pkgs, lib, ... }:

let
  hostname = "sns61";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
in {

  # Import common configuration for all machines (locale, SSHd,
  # updates...)
  imports = [ common ];
  
  environment.systemPackages = with pkgs; [
    git
    lkl lmdb python39Full e2fsprogs gnumake wget
    vim tmux
  ];

  virtualisation.docker.enable = true;

  users.mutableUsers = false;

  # For Faasten experiments
  users.users.yuetan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "tan-yue";
  };
  
  users.users.alevy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "alevy";
  };
  
  users.users.cherrypiejam = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "cherrypiejam";
  };

  users.users.npopescu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "nataliepopescu";
  };

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
