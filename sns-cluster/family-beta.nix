{ config, pkgs, lib, ... }:

let
  cfg = config.sns-machine.family.beta;

in
{
  options.sns-machine.family.beta = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    bootDisks = lib.mkOption {};

    swapPartUUIDs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf (config.sns-machine.enable && cfg.enable) (let

    enumeratedBootDisks =
      lib.imap0 (i: bootDiskCfg:
        bootDiskCfg // { idx = i; mountpoint = "/boot${toString i}"; }
      ) (builtins.sort (a: b:
        # Ensure that the boot devices have a consistent order, based
        # on their UUIDs. We match the disks to mountpoints below, and
        # don't want Grub to get confused.
        builtins.lessThan a.partUUID b.partUUID) cfg.bootDisks);

  in
  {
    hardware = {
      enableRedistributableFirmware = true;
      cpu.intel.updateMicrocode = true;
    };

    boot = {
      loader.grub = {
        enable = true;
        version = 2;
        mirroredBoots =
          builtins.map (bootDiskCfg: {
            devices = [ bootDiskCfg.diskNode ];
            path = bootDiskCfg.mountpoint;
          }) enumeratedBootDisks;
        extraConfig = ''
          serial --unit=0 --speed=115200
          terminal_input serial console
          terminal_output serial console
        '';
      };

      initrd.availableKernelModules = [
        "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod"
      ];
      kernelModules = [ "kvm-intel" ];
      kernelParams = [ "console=ttyS0,115200" ];
    };

    fileSystems =
      builtins.listToAttrs (
        builtins.map (bootDiskCfg:
          lib.nameValuePair bootDiskCfg.mountpoint {
            device = "/dev/disk/by-uuid/${bootDiskCfg.partUUID}";
            fsType = "vfat";
          }
        ) enumeratedBootDisks
      );

    swapDevices =
      builtins.map (partUUID: {
        device = "/dev/disk/by-uuid/${partUUID}"; })
        cfg.swapPartUUIDs;
  });
}
