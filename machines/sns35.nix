{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "dabd6fbb";
    hostName = "sns35";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee20579d031";
        partUUID = "AA27-F5BD";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2057a0efd";
        partUUID = "2037-BBA7";
      } ];
      swapPartUUIDs = [
        "8ef162ee-1137-4cd8-ad5b-b2aefb2dfad6"
        "76324f16-648f-44d0-b5ec-527675c995f3"
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
