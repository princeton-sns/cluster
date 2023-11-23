{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "93dc2efa";
    hostName = "sns55";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b01dd732";
        partUUID = "52E5-550F";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2056e79b0";
        partUUID = "EBFB-21FF";
      } ];
      swapPartUUIDs = [
        "6202fa9c-24b4-4c93-a9f1-67d9f693e156"
        "b025494b-28c3-4128-ab4a-31f44155f13d"
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
