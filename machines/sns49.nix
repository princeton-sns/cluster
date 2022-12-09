# Configured as a workstation for @linanqinqin

{ config, pkgs, ... }:

let
  hostname = "sns49";
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

  users.users.linanqinqin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9XMuiS7A+rQq2Q7/wIwqFCdbBEI0vXEoLU0DCwPl1KAfvdMM1w46y6+WAv66NMgjDa9wcwjdTBugMdMvWfm6UnEV7XIEbYtK9C9NO4/2gYMcIuMU2KHhoMJ86CIKGrwTDvvmvnFuPdrtIrhH66fg2qPMMUPhlQ93KlFsD+bKdQaKIIewLQaPgECuR/wb8a5qmmpAGdGLMGu+RXVJO71kiPdO999V0g1+pBA1FOqkuUUiE7nYQQfZl5PiaiqnI4PeR5qV1HWOkpNESfdzkrMXG/aa9/sOjl/q3DK6kmAIy0iaqm4V7SWWSz7WCQIXAWfFORdbpMaCtDaRPMShzQY6F linanqinqin@linanqinqindeMacBook-Pro.local
" ];
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
