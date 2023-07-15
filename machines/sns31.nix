{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "c722e193";
    hostName = "sns31";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25ac85c0c";
        partUUID = "E885-750C";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25ace7001";
        partUUID = "EB41-923D";
      } ];
      swapPartUUIDs = [
        "b4349614-2956-49fe-a3a5-9647fdcdacaf"
        "4243c066-5d9d-46d1-bb2b-534aa2855134"
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
