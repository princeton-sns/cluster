{ config, pkgs, lib, ... }:

let
  cfg = config.sns-machine;

  zfsHomeUsers =
    lib.filterAttrs (user: userCfg:
      userCfg.snsZFSPersistHome)
      config.users.users;

  zfsSnapPruneRepo = builtins.fetchGit {
    url = "https://git.currently.online/leons/zfs-snap-prune.git";
    rev = "9a77793f5cf4909b4f7b062d385317269f76b437";
    ref = "refs/heads/main";
  };

  nixpkgs2305 = let
    rev = "4f138cd546fd0a32c4c0b576de10b34f120b48ce";
  in import (builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "sha256:0vkl3xzhpjyrq10q405p3b1d4zgfxpq6x8bv26zyhbwk7my7nzwd";
  }) {};

in
{
  imports = [
    ./family-alpha.nix
    ./family-beta.nix
    ./family-gamma.nix
    ./filesystems.nix
    "${zfsSnapPruneRepo}/module.nix"
  ];

  # We use a patched version of the filesystems module, to be able to
  # dynamically generate mountpoints based on user's home
  # directories. For more info on this, see [1].
  #
  # [1]: https://github.com/NixOS/nixpkgs/issues/24570.
  disabledModules = [
    "tasks/filesystems.nix"
  ];

  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
      options = {
        snsZFSPersistHome = lib.mkOption {
          type = lib.types.bool;
          default = name != "root" && config.isNormalUser;
        };

        # TODO: privacy concerns. Is there some way to protect this, but still
        # force everyone to be reachable, and quickly be able to build a list of
        # emails for a set of machines?
        contactEmail = lib.mkOption {
          # We allow null here, but have an assertion for non-null below. This
          # allows us to generate a nicer error message.
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
    }));
  };

  options.sns-machine = {
    enable = lib.mkOption {
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable ({
    assertions = [ (let
      machineFamiliesEnabled = lib.attrNames (
        lib.filterAttrs (family: familyCfg:
          familyCfg.enable) cfg.family);
    in {
      assertion = lib.length machineFamiliesEnabled  <= 1;
      message = "At most one machine family can be enabled at a time. "
                + "Enabled families: ${
                  lib.concatStringsSep ", " machineFamiliesEnabled}.";
    }) (let
      invalidHomeUsers = lib.attrNames (
        lib.filterAttrs (user: userCfg:
          userCfg.home != "/home/${user}")
          zfsHomeUsers);
    in {
      assertion = lib.length invalidHomeUsers == 0;
      message = "Users with snsZFSPersistHome must have their home directory "
                + "set to \"/home/$USER\". Check ${
                  lib.concatStringsSep ", " invalidHomeUsers}";
    }) (let
      noContactUsers = lib.attrNames (
        lib.filterAttrs (user: userCfg:
          userCfg.isNormalUser && userCfg.contactEmail == null)
          config.users.users);
    in {
      # Disabled for now because of spam concerns
      assertion = true || lib.length noContactUsers == 0;
      message = "Users must have a valid contactEmail configured and be "
                + "reachable at this address. Check ${
                  lib.concatStringsSep ", " noContactUsers}.";
    }) ];

    # ---------- Misc System Configuration -------------------------------------
    #
    # All services configured on these systems should take into account that
    # state outside of dedicated ZFS volumes is not persisted across reboots.
    # Store state in a directory in `/var/state` or a dedicated ZFS file system
    # under `rpool/state/` (automatically included in backups).

    time.timeZone = "America/New_York";

    networking.domain = "cs.princeton.edu";

    # Provide a selection of generally useful packages by default:
    environment.systemPackages = with pkgs; [
      vim wget bc htop iotop tmux gitAndTools.gitFull gitAndTools.git-annex
      zip unzip nload mtr nmap sipcalc gnupg rclone pciutils usbutils
      nix-prefetch-git ipmitool

      # TODO: move into environment for syncoid command
      lzop mbuffer
    ];

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      hostKeys = [ {
        path = "/var/state/openssh-host-keys/ssh_host_ed25519_key";
        type = "ed25519";
      } {
        path = "/var/state/openssh-host-keys/ssh_host_rsa_key";
        type = "rsa";
        bits = "4096";
      } ];
    };

    system.activationScripts."ssh-ensure-host-keys-dir" = ''
      mkdir -p /var/state/openssh-host-keys
      chmod 700 /var/state/openssh-host-keys
    '';

    # Operator SSH keys:
    users.users.root.openssh.authorizedKeys.keys = [
      # alevy
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0UMDPmdytTJ2J1y/FsvReZRFTl7WA2HB0GVMWyUP5R"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBbxJcPHPkhNwCuoa0wJvK4WHT/GVX7g3JjJFTZvXSc6eDgSr6r1oynlNO5jlr68AVAWxbkckfw6TAtdfuCxcrZQe+xMJ0UWmstR5Ed7poAbkU6uSrA8nLI0tl3Swuc87wq/qpX8nkEJR5oAGzNp0ZPTH7kshx3ZE/2n3XXLuyaYme68YhKk3MiVU8jz5J9NUeH4zeTdHKFMnydy4ORg+pVc/8esauQyiITk/SDRXIO56DEnpZQGu96gHVBDwtx8GxbnmEnumKsxiOR3aXbGFVF1FhlDyUKQKqm28GBJyByRiQuDVI06+ZhCLzrq3wiPbtxmctdBcVLP2KpqPYQPWZ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCReHVoVeXfqK8bbIcotwhUBrt7u2T6IQNKMysmJF42"

      # leons (smartcards only)
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9XgOJNVpO00+p04GwoL0viFco4p24PrsPzvsCOiAETJ6ttYiOFjYrpjQvNLsDse0PcW+duhtjyyp+Y7JZaOTeG6FX1Y8j6gDCUML58f4NlKtnWzfMftYkVO8QeYzdjJhG3J2zBXuqMmen7elVgZouvM/H47X620q7BssTTS1YIVnXxNn5jip8UbSJ1073MnUuTjSGrmS9yyLQx4Ka9/u6zzPDASw6OWXyzoXkWVpU5VzAqYk8Ob9C+lFQw5LMERsQBADoNB+kg/m+OoKS7XXu9+WFdTKsqhy7/c6hijRPaNsP/JRfsxEyjF+Y8LyokU2OXq0MWM0xZrt8O3/DsXAKqyIrGCVPQX+eeXvqP8LusFm2CDe8zoUeyLXvBdZX6Xxyy00OHHQRsuIbBYCJOUMbmDwIcEaC4DELjcNFZXJQYhj2hvB2sQvTMjnS58FDkD+IgVTTlTTzkEiDwbIV6lHbSqzA6AvZtZXd1+rQ4wFIT0clQhAGpBWKN+8Cotl51yC+P+nbU9xlCXM17Q3Pev2sjZFx1VU3oa5SEzEv74aWhUDCaATun/ebi/1Scm3ekOsiPVHuUBm9a2GUMYIuAOTL6W9AM2zZJ8xWkJw5Rj1eQnIDwD9izCRR1gJXlkTYwLn6ZnLawX6FS6Vvj5NV8mjjU4xlhnwaWF0b/Jmm3E966w== cardno:9 040 274"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGtanFKH41B3/4piGmhl82gh0AsGACkDV85vUcWHJhrY8AkrVSphnrpL62gY7R6/Rx3AZ+6A+GYoICJa/V4qWUkKryOavZ9xe164JeFtFFN/CrDsIWCLdMyvQ5JO0zc5QmUCRX/UfRzjRzf+y6QdnIoNw5tV2E0zQj9g68I7uNEuuYNmQLg2EyoOE0qtxFTMBEcRzocvVx2QoErDOWD17fDhjc1kR7D7lMVI8jIqRFEQQO3ke6YTXkJAVtjjELqcnSERq58qDKZm9HuYtiUe8cgiBe1UdD8lHTwAGbEE1mSV0IsAOxEoo1BkjBhrYqUxPwfObZwt6TkTF/tbuZkU+m4RU09j2FqliXe66cpDeyAs/C88QObsrqCHb3JJa1GtAp8JSeiELadYYKgiVJibVpb8mBksRxeCruk1Jr9DeAmKVeF/tTect9YALD8qTQNnsyBh0r7HMxyBEze5O6RAV2rnjWHxYIj9oBj8V/q+cykEUXfc4M8rHn/dt72h/LcL3jaYvQwecJjOCW2xW2/sGWkhJ7ittPV7aeOcL9TqG6mggukBjgM/TtPFxsjduxNZ2YSUgVHdmaRsfyDDMfXtdjfCdRcCxslRwQTgl8X2Kb5M0CsQSmWas7vb6JhBLyDPYWWJyxSzb98P3flq9qZjQlVaAiP6asYLDSoKMDYoY7Rw== cardno:0005 00007D5B"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjLuM7C6emv+xAFYnXA+mSUKmMEmKDM0A6WzZ0HliFb cardno:23 559 180"
    ];

    # Mutable user state is not persisted.
    users.mutableUsers = false;

    # --> Either one of the following must be set:

    # Set a hashed root password:
    users.users.root.initialHashedPassword =
      "$6$zXOHOCP4zSZWJQgY$6vFWG3SOSzZf88aTuOeZ5mz1ep0XB.PFy9Hw66rlm58BIvtr6lLv4Q2rq.72loPJc1f6PCEHUqJ.1ZFX.Fjro1";
    users.users.root.hashedPassword =
      config.users.users.root.initialHashedPassword;

    # Don't set a root password requires setting the `allowNoPasswordLogin`
    # option.  It is named rather unfortunate: it does not mean that a user can
    # login to the system without a password, but rather that we allow NixOS to
    # build a system configuration where no user has a password set. We use
    # password-less SUDO and SSH keys, so this is not an issue in our case.
    # users.allowNoPasswordLogin = true;

    # Enable the firewall (OpenSSH is always automatically allowed):
    networking.firewall.enable = true;

    # Save energy when system idling:
    powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

    # ---------- Bootloader Configuration --------------------------------------

    # Provide an iPXE shell as an "escape" hatch to load a NixOS installer:
    boot.loader.grub.ipxe.shell = ''
      #!ipxe
      shell
    '';

    # Configure iPXE to expose its console on the SOL port:
    boot.loader.grub.extraFiles."ipxe.lkrn" = lib.mkForce
      "${pkgs.ipxe.overrideAttrs (_: {
        preConfigure = ''
          sed -i 's|^//\(#define.*CONSOLE_SERIAL\)|\1|g' src/config/console.h
        '';
      })}/ipxe.lkrn";

    # ---------- ZFS Transient Root File System Support ------------------------

    boot.initrd.postDeviceCommands = ''
      # Just to make sure the device is up. TODO: check to see whether there is
      # a more reliable way to do this.
      sleep 5

      # Don't allow these commands to fail the boot process. If these fail,
      # there's a chance that importing the pool & not rolling back will
      # still work in the later stages of the boot process.
      zpool import -f rpool || true
      zfs rollback rpool/local/transient/root@blank || true
    '';

    # The patched filesystems.nix module no longer populates
    # `boot.supportedFilesystems` from `config.fileSystems` due to a circular
    # dependency on `users.users`. Set it manually:
    boot.supportedFilesystems = [
      "zfs" "vfat"
    ];

    fileSystems = {
      "/" = {
        device = "rpool/local/transient/root";
        fsType = "zfs";
      };

      "/nix" = {
        device = "rpool/local/nix";
        fsType = "zfs";
      };

      "/var/state" = {
        device = "rpool/state/system";
        fsType = "zfs";
      };
    } // (
      # Automatically generate mount points for user ZFS home directories:
      lib.mapAttrs' (user: userCfg:
        lib.nameValuePair userCfg.home {
          device = "rpool/state/home/${user}";
          fsType = "zfs";
        })
        zfsHomeUsers
    );

    # Export the active ZFS home file systems, such that the backup service can
    # read this file and retire homes accordingly.
    system.extraSystemBuilderCmds = ''
      ln -s ${
        pkgs.writeText "active-zfs-homes.txt" (
          lib.concatStringsSep "\n" (
            builtins.map (user:
              "rpool/state/home/${user}")
              (lib.attrNames zfsHomeUsers)))
      } $out/active-zfs-homes
    '';

    # Create a ZFS home directory automatically, if
    # `users.users.<name>.snsZFSPersistHome` is set. This will be automatically
    # included in backups, and removed by the backup machine once the user is no
    # longer present (although still included in backups).
    system.activationScripts."zfs-create-homes" =
      lib.concatStringsSep "\n\n" (
        builtins.map (user: ''
          if ZFS_HOME_CREATE=`${pkgs.zfs}/bin/zfs create -o mountpoint=legacy rpool/state/home/${user} 2>&1`; then
             echo 'Created ZFS file system for "${user}" home directory.'
          else
             if echo "$ZFS_HOME_CREATE" | grep "dataset already exists" 2>&1 >/dev/null; then
               echo 'Reusing existing ZFS file system for "${user}" home directory.'
             else
               echo 'Unknown error occured while creating ZFS file system for "${user}" home directory:'
               echo "$ZFS_HOME_CREATE"
             fi
          fi
        '') (lib.attrNames zfsHomeUsers));

    # Persist the NixOS configuration.
    environment.etc.nixos = {
      source = "/var/state/nixos";
    };

    # ---------- Syncoid ZFS Pull-based Backups --------------------------------

    users.users.backup-ssh = let
      # This uses a slightly patched version of the `only` script [1],
      # to limit the commands that can be run on this user with the
      # backup SSH key. For further documentation on how `only` works,
      # see [1].
      #
      # The ZFS commands are run in a user context. This requires
      # giving this user the appropriate permissions on the allowed
      # data sets, for example:
      #
      #     zfs allow backup-ssh bookmark,hold,send,snapshot,mount,destroy rpool/state
      #
      # [1]: https://at.magma-soft.at/sw/blog/posts/The_Only_Way_For_SSH_Forced_Commands/
      zpoolPattern = ''[[:alnum:]_\-]\+'';
      zfsPattern = ''[[:alnum:]\/_\-]\+'';
      snapNamePattern = ''[[:alnum:]_\:\-]\+'';
      snapPattern = "'${zfsPattern}\\(@\\|'@'\\)${snapNamePattern}'";
      onlyrules = pkgs.writeText "backup-ssh-onlyrules" ''
        \:^echo -n$:{p;q}
        \:^cat /run/current-system/active-zfs-homes$:{p;q}
        \:^exit$:{p;q}
        \:^zpool get -o value -H feature@[[:alnum:]_]\+ '${zpoolPattern}'$:{p;q}
        \:^zfs list -o name,origin -t filesystem,volume -Hr '${zfsPattern}'$:{p;q}
        \:^zfs get -H syncoid\:sync '${zfsPattern}'$:{p;q}
        \:^zfs get -Hpd 1 -t snapshot guid,creation '${zfsPattern}'$:{p;q}
        \:^zfs snapshot '${zfsPattern}'@${snapNamePattern}$:{p;q}
        \:^zfs send\( -nvP\)\?\( -I ${snapPattern}\)\? ${snapPattern}\( | lzop | mbuffer -q -s 128k -m 16M 2>/dev/null\)\?$:{p;q}
        \:^zfs destroy -r 'rpool/state/home/${zfsPattern}'$:{p;q}
      '';
      # onlyrules = pkgs.writeText "backup-ssh-onlyrules" (builtins.readFile ./onlyrules.example);
      onlyrc = pkgs.writeText "backup-ssh-onlyrc" ''
        show_allowed
        show_denied
      '';
      patchedOnly =
        pkgs.writeScript "backup-ssh-only" (
          builtins.replaceStrings
            [ "LOGGER=logger" "SED=sed" "WHICH=which"
              "RULES=~/.onlyrules" "RCFILE=~/.onlyrc" ]
            [ "LOGGER=${pkgs.logger}/bin/logger" "SED=${pkgs.gnused}/bin/sed"
              "WHICH=${pkgs.which}/bin/which" "RULES=${onlyrules}"
              "RCFILE=${onlyrc}" ]
            (builtins.readFile ./only));
    in {
      isSystemUser = true;
      group = "backup-ssh";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        ("command=\"${patchedOnly} echo cat exit zfs zpool\" "
         + "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNcB6840dOUw3h8ckWvDarndt14SGO3eCsmAC3zkYUN sns-cluster-zfs-backups")
      ];
    };

    users.groups.backup-ssh = {};

    system.activationScripts."backup-ssh-zfs-permissions" = {
      deps = [ "users" "groups" ];
      text = ''
        ${pkgs.zfs}/bin/zfs allow backup-ssh bookmark,hold,send,snapshot,mount,destroy rpool/state
      '';
    };

    services.zfs-snap-prune = {
      enable = true;
      mode = "prepare_first";
      package = nixpkgs2305.callPackage zfsSnapPruneRepo {};
      jobs = [ {
        label = "Local rpool state";
        pool = "rpool";
        dataset = "/state";
        recursive = true;
        snapshot_pattern = "^syncoid_sns26_(.*)$";
        snapshot_time = {
          source = "capture_group";
          capture_group = 1;
          format = "chrono_fmt";
          chrono_fmt = "%Y-%m-%d:%H:%M:%S-GMT%:z";
        };
        retention_policy = "simple_buckets";
        retention_config = {
          latest = 1;
          daily = 7;
        };
      } ];
    };

    # ---------- Monitoring ----------------------------------------------------

    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        # Disabled by default, this is interesting to diagnose performance
        # bottlenecks caused by e.g., network activity:
        "interrupts"
      ];
      openFirewall = false;
      listenAddress = "0.0.0.0";
    };

    # Add rule to the firewall to give SNS26 access to the node exporter:
    networking.firewall.extraCommands = ''
      iptables -A INPUT -p tcp -s 128.112.7.126 --dport ${
        toString config.services.prometheus.exporters.node.port} -j ACCEPT
    '';
  });
}
