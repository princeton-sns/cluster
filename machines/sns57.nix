{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "292ab2b1";
    hostName = "sns57";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee205724b8a";
        partUUID = "3A45-C519";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee20573c3b4";
        partUUID = "F1DB-66A3";
      } ];
      swapPartUUIDs = [
        "1aea070e-bcfa-439c-baeb-b23869be1120"
        "d82b61ff-3215-4f5b-92a0-1ec3509165e9"
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
