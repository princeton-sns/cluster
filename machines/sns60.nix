{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "19258b45";
    hostName = "sns60";

    interfaces."enp4s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.gamma = {
      enable = true;

      bootDiskNode = "/dev/disk/by-id/wwn-0x50025385503bc2ef";
      bootPartUUID = "6264-C1BC";
      swapPartUUID = "34efba60-d1a4-43c9-b036-9f1f1c03063d";
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
