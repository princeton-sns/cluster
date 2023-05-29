{ config, pkgs, lib, ... }:

let
  cfg = config.sns-machine.family.gamma;

in
{
  options.sns-machine.family.gamma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    bootDiskNode = lib.mkOption {
      type = lib.types.str;
    };

    bootPartUUID = lib.mkOption {
      type = lib.types.str;
    };

    swapPartUUID = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf (config.sns-machine.enable && cfg.enable) ({
    hardware = {
      enableRedistributableFirmware = true;
      cpu.intel.updateMicrocode = true;
    };

    boot.loader.grub = {
      enable = true;
      version = 2;
      mirroredBoots = [ {
        devices = [ cfg.bootDiskNode ];
        path = "/boot0";
      } ];
    };

    boot = {
      initrd.availableKernelModules = [
        "ehci_pci" "ahci" "isci" "mpt3sas" "usbhid" "usb_storage" "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ "kvm-intel" ];
    };

    fileSystems."/boot0" = {
      device = "/dev/disk/by-uuid/${cfg.bootPartUUID}";
      fsType = "vfat";
    };

    swapDevices = [ {
      device = "/dev/disk/by-uuid/${cfg.swapPartUUID}";
    } ];
  });
}
