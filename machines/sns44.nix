# @yuetan uses this machine as a testbed for securefaas project

{ config, pkgs, ... }:

let
  hostname = "sns44";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
  snapfaasSrc = pkgs.fetchFromGitHub {
    owner = "princeton-sns";
    repo = "snapfaas";
    rev = "9791be9d108dd45abf50d9a62681d7a0f61613d5";
    sha256 = "sha256-ZJS7GDW7lBILrMKrKXxLAw5gjKunSai27RO3oZvJAn4=";
  };
  snapfaas = (import snapfaasSrc { inherit pkgs; release = false; }).snapfaas;
in {

  # Import common configurat for all machines (locale, SSHd, updates...)
  imports = [ common ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    snapfaas lkl lmdb python39Full e2fsprogs gnumake wget
    vim tmux
  ];

  # Expose port for development snapfaas webhook server
  networking.firewall.allowedTCPPorts = [ 8080 ];

  fileSystems."/nfs/home" = {
    device = "adam-new.cs.princeton.edu:/home";
    fsType = "nfs4";
  };


  programs.mosh.enable = true;

  virtualisation.docker.enable = true;

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
  
  ## Kevin Wang (@kw1122) working on snapfaas grader over summer '22
  users.users.fierycandy = {
    isNormalUser = true;
    extraGroups = [ "kvm" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "kw1122";
  };

  users.users.atli = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "ATLi2001";
  };
  
  users.users.scaspin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "docker" ];
    openssh.authorizedKeys.keys = utils.githubSSHKeys "scaspin";
  };
  
}
