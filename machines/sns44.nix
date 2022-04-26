# @yuetan uses this machine as a testbed for securefaas project

{ config, pkgs, ... }:

let
  hostname = "sns44";
  common = (import ./common.nix) { hostname = hostname; };
  utils = import ../utils;
  snapfaasSrc = pkgs.fetchFromGitHub {
    owner = "princeton-sns";
    repo = "snapfaas";
    rev = "eeaeea41146b2f5faea9d588f3bdba3a0c178cf3";
    sha256 = "0df1vr9anh7i360j9ngrlbqxa950j7zz4gd8bhzd8rpbwjn5yd0b";
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

  # open up specified ports
  networking.firewall.allowedTCPPorts = [ 8888 ];

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
  
  ## Only through Spring '22
  users.users.moma = {
    isNormalUser = true;
    extraGroups = [ "kvm" ];
    openssh.authorizedKeys.keys = (utils.githubSSHKeys "moinmir") ++ (utils.githubSSHKeys "Marinabeshai");
  };
  
  ## Only through Spring '22
  users.users.hina = {
    isNormalUser = true;
    extraGroups = [ "kvm" ];
    openssh.authorizedKeys.keys = (utils.githubSSHKeys "nfinkle") ++ (utils.githubSSHKeys "hillelkoslowe");
  };
}
