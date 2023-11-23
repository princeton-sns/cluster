{ config, pkgs, lib, ... }:

{
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "fa526a52";
    hostName = "sns49";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2056e671c";
        partUUID = "1854-B4E0";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25abaf911";
        partUUID = "A9EA-36D2";
      } ];
      swapPartUUIDs = [
        "6f60a562-e50e-4751-9384-a739cf107b6c"
        "9cef0df7-392c-420e-906f-36b2f6a4a4dd"
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
