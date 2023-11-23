{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "0e5eb4d2";
    hostName = "sns33";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b01fe0fe";
        partUUID = "0E6B-35DA";
      } ];
      swapPartUUIDs = [ "777dd6c5-d51e-40c0-b3ff-7e4b312d7185" ];
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
