{ config, pkgs, lib, ... }:

let
  cfg = config.sns-machine;

  zfsHomeUsers =
    lib.filterAttrs (user: userCfg:
      userCfg.snsZFSPersistHome)
      config.users.users;

in
{
  imports = [
    ./family-gamma.nix
    ./filesystems.nix
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
      options.snsZFSPersistHome = lib.mkOption {
        type = lib.types.bool;
        default = name != "root" && config.isNormalUser;
      };
    }));
  };

  options.sns-machine = {
    enable = lib.mkOption {
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable ({
    assertions = [ {
      assertion = (lib.length (
        lib.filter (en: en) (
          lib.mapAttrsToList (
            _familyName: familyCfg: familyCfg.enable)
            cfg.family))) <= 1;
      message = "At most one machine family can be enabled at a time.";
    } {
      assertion = lib.length (
        lib.attrNames (
          lib.filterAttrs (user: userCfg:
            userCfg.home != "/home/${user}")
            zfsHomeUsers)) == 0;
      message = "Users with snsZFSPersistHome must have their home directory "
        + "set to \"/home/$USER\"";
    } ];

    # ---------- Misc System Configuration -------------------------------------
    #
    # All services configured on these systems should take into account that
    # state outside of dedicated ZFS volumes is not persisted across reboots.
    # Store state in a directory in `/var/state` or a dedicated ZFS file system
    # under `rpool/state/` (automatically included in backups).

    time.timeZone = "America/New_York";

    environment.systemPackages = with pkgs; [
      vim wget htop nload tmux

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

    # Mutable user state is not persisted.
    users.mutableUsers = false;

    # --> Either one of the following must be set:

    # Set a hashed root password:
    users.users.root.hashedPassword =
      "$6$zXOHOCP4zSZWJQgY$6vFWG3SOSzZf88aTuOeZ5mz1ep0XB.PFy9Hw66rlm58BIvtr6lLv4Q2rq.72loPJc1f6PCEHUqJ.1ZFX.Fjro1";

    # Don't set a root password requires setting the `allowNoPasswordLogin`
    # option.  It is named rather unfortunate: it does not mean that a user can
    # login to the system without a password, but rather that we allow NixOS to
    # build a system configuration where no user has a password set. We use
    # password-less SUDO and SSH keys, so this is not an issue in our case.
    # users.allowNoPasswordLogin = true;

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

    system.activationScripts."backup-ssh-zfs-permissions" = ''
      ${pkgs.zfs}/bin/zfs allow backup-ssh bookmark,hold,send,snapshot,mount,destroy rpool/state
    '';
  });
}
