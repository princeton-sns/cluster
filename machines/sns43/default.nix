{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "428205a1";
    hostName = "sns43";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b024c61f";
        partUUID = "3921-AE59";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25acf9228";
        partUUID = "6B50-2AFD";
      } ];
      swapPartUUIDs = [
        "29b106d3-4955-4b14-9bc8-3f7686cae714"
        "62a185e3-7e7b-49f5-9422-8b19361188ee"
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
