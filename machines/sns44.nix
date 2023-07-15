{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "fe81c10c";
    hostName = "sns44";

    interfaces."enp1s0f1" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25acc6d1c";
        partUUID = "D6A2-8C75";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b01c4c8c";
        partUUID = "7218-2831";
      } ];
      swapPartUUIDs = [
        "28b6f349-0383-4e30-a1ed-8e9856743111"
        "6cf1e629-873a-4db8-80c6-674fa81847fd"
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
