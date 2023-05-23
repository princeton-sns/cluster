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

    boot = {
      loader.grub = {
        enable = true;
        version = 2;
        device = cfg.bootDiskNode;
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

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/${cfg.bootPartUUID}";
      fsType = "vfat";
    };

    swapDevices = [ {
      device = "/dev/disk/by-uuid/${cfg.swapPartUUID}";
    } ];
  });
}
