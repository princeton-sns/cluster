{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "326ac1ae";
    hostName = "sns46";

    interfaces."enp1s0f1" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2057821ec";
        partUUID = "DF1F-1A9A";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25acf2504";
        partUUID = "9359-5368";
      } ];
      swapPartUUIDs = [
        "200dc0d3-d620-4803-8749-0f98deb2c20b"
        "ac51cd77-e774-47f1-b278-039b504cd92f"
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
