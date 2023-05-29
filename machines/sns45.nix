{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "18e30b23";
    hostName = "sns45";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25abfe404";
        partUUID = "BFC9-B709";
      } ];
      swapPartUUIDs = [ "43729736-39c3-4895-abc2-bb7f698b0d96" ];
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
