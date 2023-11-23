{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "7eac84cc";
    hostName = "sns41";

    interfaces."enp1s0f1" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b013dd19";
        partUUID = "009F-1B97";
      } ];
      swapPartUUIDs = [ "e27730be-65f9-4e7d-bf61-3dbe80d2a6dd" ];
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
