# SNS45 Machine Log

Current issues:
- Permanent data corruption. Reinstall (and potentially drive swap) required.

## 2023-11-22 Data Corruption

ZFS has detected permanent data corruption:
```
[root@sns57:~]# zpool status -v
  pool: rpool
 state: ONLINE
status: One or more devices has experienced an error resulting in data
        corruption.  Applications may be affected.
action: Restore the file in question if possible.  Otherwise restore the
        entire pool from backup.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-8A
  scan: resilvered 2.47G in 00:03:54 with 2 errors on Fri Jul 14 23:18:26 2023
config:

        NAME        STATE     READ WRITE CKSUM
        rpool       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb4    ONLINE       0     0     0
            sda4    ONLINE       0     0     0

errors: Permanent errors have been detected in the following files:

        //etc/zfs/zpool.cache
        rpool/local/transient/root:<0x484>
```

SMART status of all drives is still good.

