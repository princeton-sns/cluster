{ config, pkgs, lib, ... }:

{
  imports = [
    ../sns-cluster
  ];

  networking = {
    hostId = "${TMPLSTR_HOST_ID}";
    hostName = "${TMPLSTR_HOSTNAME}";

    interfaces."${TMPLSTR_UPLINK_IFACE}" = {
      useDHCP = true;
    };
  };

  sns-machine = {
    enable = true;

    family.gamma = {
      enable = true;

      bootDiskNode = "${TMPLSTR_BOOT_DISK_NODE}";
      bootPartUUID = "${TMPLSTR_BOOT_PART_UUID}";
      swapPartUUID = ${TMPLSTR_NULLABLE_SWAP_PART_UUID};
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "${TMPLSTR_NIXOS_VERSION}"; # Did you read the comment?
}
