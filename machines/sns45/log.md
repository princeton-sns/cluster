# SNS45 Machine Log

Current issues:
- Redundant boot drive failure

## 2023-11-22 Redundant Boot Drive Failure

- Smartctl output showing drive failure: <./log/2023-11-22_smartctl_-a_sda.txt>
- ZFS pool has marked `sda4` as FAULTED:

  ```
  [root@sns45:~]# zpool status
    pool: rpool
   state: DEGRADED
  status: One or more devices are faulted in response to persistent errors.
          Sufficient replicas exist for the pool to continue functioning in a
          degraded state.
  action: Replace the faulted device, or use 'zpool clear' to mark the device
          repaired.
    scan: scrub repaired 0B in 00:03:32 with 0 errors on Sat Jul 15 00:22:09 2023
  config:

          NAME        STATE     READ WRITE CKSUM
          rpool       DEGRADED     0     0     0
            mirror-0  DEGRADED     0     0     0
              sdb4    ONLINE       0     0     0
              sda4    FAULTED      6    61     0  too many errors

  errors: No known data errors
  ```
