# SNS46 Machine Log

Current issues:
- Disk failure

## 2023-11-22 Disk Failure

- For `sda`, smartctl is unable to read SMART data: <./log/2023-11-22_smartctl_-a_sda.txt>

  ```
  smartctl 7.3 2022-02-28 r5338 [x86_64-linux-5.15.112] (local build)
  Copyright (C) 2002-22, Bruce Allen, Christian Franke, www.smartmontools.org

  Short INQUIRY response, skip product id
  A mandatory SMART command failed: exiting. To continue, add one or more '-T permissive' options.
  ```

- SMART reports `sdb` as FAILED: <./log/2023-11-22_smartctl_-a_sdb.txt>

  ```
  === START OF READ SMART DATA SECTION ===
  SMART overall-health self-assessment test result: FAILED!
  Drive failure expected in less than 24 hours. SAVE ALL DATA.
  See vendor-specific Attribute list for failed Attributes.
  ```

- ZFS pool has marked `sda4` as FAULTED:

  ```
  [root@sns58:~]# zpool status
    pool: rpool
   state: DEGRADED
  status: One or more devices are faulted in response to persistent errors.
          Sufficient replicas exist for the pool to continue functioning in a
          degraded state.
  action: Replace the faulted device, or use 'zpool clear' to mark the device
          repaired.
    scan: resilvered 2.45G in 00:07:53 with 0 errors on Fri Jul 14 23:23:37 2023
  config:

          NAME        STATE     READ WRITE CKSUM
          rpool       DEGRADED     0     0     0
            mirror-0  DEGRADED     0     0     0
              sda4    FAULTED      3   324     0  too many errors
              sdb4    ONLINE       0     0     0

  errors: No known data errors
  ```
