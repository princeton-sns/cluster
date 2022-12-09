# @davidhliu uses this machine as a workstation

{ config, pkgs, ... }:

let
  hostname = "sns52";
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

  users.users.davidhliu= {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" ];	
    openssh.authorizedKeys.keys = utils.githubSSHKeys "LedgeDash";
  };
  
  users.users.neilagarwal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker"];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "neilsagarwal";
  };
  
  users.users.ruipan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker"];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "ruipeterpan";
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
