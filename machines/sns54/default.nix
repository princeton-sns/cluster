{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "63fdab54";
    hostName = "sns54";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2056bad25";
        partUUID = "654C-06D0";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25ac4242b";
        partUUID = "DEEA-4476";
      } ];
      swapPartUUIDs = [
        "010d994e-7c74-4b56-81bf-358e917ef4d5"
        "af1a962b-6284-4a5e-98ca-1dd223e8bb58"
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
