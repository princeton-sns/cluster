{ config, pkgs, lib, ... }:

let
  cfg = config.sns-machine.family.alpha;

in
{
  options.sns-machine.family.alpha = {
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
      # TODO: microcode updates?
    };

    boot = {
      loader.grub = {
        enable = true;
        version = 2;
        mirroredBoots = [ {
          devices = [ cfg.bootDiskNode ];
          path = "/boot0";
        } ];
        device = cfg.bootDiskNode;
        # TODO: SOL serial port & baudrate?
        # extraConfig = ''
        #   serial --unit=0 --speed=115200
        #   terminal_input serial console
        #   terminal_output serial console
        # '';
      };

      initrd.availableKernelModules = [
        "ohci_pci" "ehci_pci" "pata_amd" "sata_nv" "usbhid" "sd_mod"
      ];
      kernelModules = [ "kvm-amd" ];

      # TODO: SOL serial port & baudrate?
      # kernelParams = [ "console=ttyS0,115200" ];
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
