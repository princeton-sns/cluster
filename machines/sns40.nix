{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "9e0b0fef";
    hostName = "sns40";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25acf0dd3";
        partUUID = "7182-6C12";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b023bf7c";
        partUUID = "6137-68D2";
      } ];
      swapPartUUIDs = [
        "9b73b683-9c96-4d86-9368-f7551acf87a3"
        "69084092-e4e4-4dc6-bf9f-223cec3def26"
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
