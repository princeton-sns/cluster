{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "451e68a5";
    hostName = "sns58";

    interfaces."eno1" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b019cff0";
        partUUID = "AD41-DF10";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2055ec934";
        partUUID = "F658-C441";
      } ];
      swapPartUUIDs = [
        "05f35901-01ee-4177-bbac-97e895f7d1d1"
        "66bae048-023d-458e-88ad-cbe93c095b11"
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
