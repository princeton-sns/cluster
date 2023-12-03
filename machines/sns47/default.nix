{ config, pkgs, lib, ... }: let

  githubSSHKeys = user:
    builtins.map (record: record.key) (
      builtins.fromJSON (
        builtins.readFile (
          builtins.fetchurl "https://api.github.com/users/${user}/keys")));

in {
  imports = [
    ../../sns-cluster
  ];

  networking = {
    hostId = "2c5a3fb2";
    hostName = "sns47";

    interfaces."enp1s0f0" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.beta = {
      enable = true;

      bootDisks = [ {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee2b024c595";
        partUUID = "DC5B-F786";
      } {
        diskNode = "/dev/disk/by-id/wwn-0x50014ee25accd328";
        partUUID = "9FCD-876E";
      } ];
      swapPartUUIDs = [
        "845bded3-b77e-4557-9270-206b09de08f5"
        "05955916-3d91-477c-a90a-522ceb4b3e64"
      ];
    };
  };


  # ---- users

  users.users.alevy = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = githubSSHKeys "alevy";
  };

  users.users.nkaas = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = githubSSHKeys "nickaashoek";
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
