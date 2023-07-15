{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "aefa0501";
    hostName = "sns50";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b0184a5a";
        partUUID = "24C6-D10A";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee205740e5d";
        partUUID = "B5A0-45D0";
      } ];
      swapPartUUIDs = [
        "4d66a96c-be2b-4164-a631-88a449812e32"
        "ed22d37e-7df2-42ea-81e0-0d3c99db4445"
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
