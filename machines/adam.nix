{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "3276fa8f";
    hostName = "adam";

    interfaces."enp4s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.gamma = {
      enable = true;

      bootDiskNode = "/dev/disk/by-id/wwn-0x5000c50064255757";
      bootPartUUID = "1114-977D";
      swapPartUUID = "c08fe64d-c45e-4767-953c-561210a714f1";
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
