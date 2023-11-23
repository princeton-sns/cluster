{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "9904e2c0";
    hostName = "sns52";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25ac879f0";
        partUUID = "7861-7897";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b024dece";
        partUUID = "D737-7652";
      } ];
      swapPartUUIDs = [
        "4103ad2d-d8a2-4ff3-bc90-3fded876d32b"
        "fa445405-ba6e-4c73-b80a-bd77a417e1e0"
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
