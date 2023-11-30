{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "d4184e26";
    hostName = "sns59";

    interfaces."enp4s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.gamma = {
      enable = true;

      bootDiskNode = "/dev/disk/by-id/wwn-0x50025385503bc2f1";
      bootPartUUID = "2790-0D12";
      swapPartUUID = "1f756a46-b2c3-4b16-8294-6380a6e24e87";
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
