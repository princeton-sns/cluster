# SNS45 Machine Log

Current issues:
- Redundant boot drive failure

## 2023-11-22 Redundant Boot Drive Failure

- Smartctl output showing drive failure: <./log/2023-11-22_smartctl_-a_sda.txt>
- ZFS pool has marked `sda4` as FAULTED, with an unrecoverable data error!

  ```
  [root@sns49:~]# zpool status
    pool: rpool
   state: DEGRADED
  status: One or more devices has experienced an error resulting in data
          corruption.  Applications may be affected.
  action: Restore the file in question if possible.  Otherwise restore the
          entire pool from backup.
     see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-8A
    scan: scrub repaired 584K in 00:01:19 with 0 errors on Sat Jul 15 00:17:48 2023
  config:

          NAME        STATE     READ WRITE CKSUM
          rpool       DEGRADED     0     0     0
            mirror-0  DEGRADED     0     0     0
              sda4    FAULTED     10     0    10  too many errors
              sdb4    ONLINE       0     0     0

  errors: 1 data errors, use '-v' for a list
  ```
