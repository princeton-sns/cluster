{ config, pkgs, lib, ... }:

let
  githubSSHKeys = user:
    builtins.map (record: record.key) (
      builtins.fromJSON (
        builtins.readFile (
          builtins.fetchurl "https://api.github.com/users/${user}/keys")));

in
{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "9d10b77c";
    hostName = "sns30";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b01fc4d2";
        partUUID = "19B6-4039";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25ac3d351";
        partUUID = "FB05-5BB3";
      } ];
      swapPartUUIDs = [
        "b18d8c6b-fdba-454b-be97-9b5e65668e6c"
        "95a4771c-9a18-4f6b-a1ab-04b2d71ded53"
      ];
    };
  };

  users.users.npopescu = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = githubSSHKeys "nataliepopescu";
  };

  users.users.leons = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = githubSSHKeys "lschuermann";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
