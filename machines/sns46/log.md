# SNS46 Machine Log

Current issues:
- Disk failure

## 2023-11-22 Disk Failure

Boot log (via IPMI SOL) showing that the system is unable to even
locate the boot pool:

```
loading module dm_mod...
running udev...
Starting version 251.16
[    1.481997] usb usb1-port2: over-current condition
kbd_mode: KDSKBMODE: Inappropriate ioctl for device
starting device mapper and LVM...
[   11.021361] ata4.00: exception Emask 0x0 SAct 0x20002040 SErr 0x0 action 0x0
[   11.028427] ata4.00: irq_stat 0x40000008
[   11.032359] ata4.00: failed command: READ FPDMA QUEUED
[   11.037500] ata4.00: cmd 60/00:e8:88:3d:a0/01:00:21:00:00/40 tag 29 ncq dma 131072 in
[   11.037500]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   11.053570] ata4.00: status: { DRDY ERR }
[   11.057580] ata4.00: error: { UNC }
[   11.066165] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x700 phys_seg 2 prio class 0
[   13.046358] ata4.00: exception Emask 0x0 SAct 0x800000 SErr 0x0 action 0x0
[   13.053245] ata4.00: irq_stat 0x40000008
[   13.057175] ata4.00: failed command: READ FPDMA QUEUED
[   13.062312] ata4.00: cmd 60/00:b8:88:3d:a0/01:00:21:00:00/40 tag 23 ncq dma 131072 in
[   13.062312]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   13.078380] ata4.00: status: { DRDY ERR }
[   13.082392] ata4.00: error: { UNC }
[   13.090924] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
[   15.512331] ata4.00: exception Emask 0x0 SAct 0x3008000 SErr 0x0 action 0x0
[   15.519301] ata4.00: irq_stat 0x40000008
[   15.523232] ata4.00: failed command: READ FPDMA QUEUED
[   15.528369] ata4.00: cmd 60/00:c0:88:3d:a0/01:00:21:00:00/40 tag 24 ncq dma 131072 in
[   15.528369]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   15.544436] ata4.00: status: { DRDY ERR }
[   15.548450] ata4.00: error: { UNC }
[   15.557637] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x700 phys_seg 2 prio class 0
[   17.512398] ata4.00: exception Emask 0x0 SAct 0x80000 SErr 0x0 action 0x0
[   17.519193] ata4.00: irq_stat 0x40000008
[   17.523119] ata4.00: failed command: READ FPDMA QUEUED
[   17.528256] ata4.00: cmd 60/00:98:88:3d:a0/01:00:21:00:00/40 tag 19 ncq dma 131072 in
[   17.528256]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   17.544322] ata4.00: status: { DRDY ERR }
[   17.548336] ata4.00: error: { UNC }
[   17.557650] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
[   20.116367] ata4.00: exception Emask 0x0 SAct 0x1004020 SErr 0x0 action 0x0
[   20.123338] ata4.00: irq_stat 0x40000008
[   20.127271] ata4.00: failed command: READ FPDMA QUEUED
[   20.132406] ata4.00: cmd 60/00:c0:88:3d:a0/01:00:21:00:00/40 tag 24 ncq dma 131072 in
[   20.132406]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   20.148474] ata4.00: status: { DRDY ERR }
[   20.152486] ata4.00: error: { UNC }
[   20.161505] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x700 phys_seg 2 prio class 0
[   22.212357] ata4.00: exception Emask 0x0 SAct 0x400 SErr 0x0 action 0x0
[   22.218983] ata4.00: irq_stat 0x40000008
[   22.222912] ata4.00: failed command: READ FPDMA QUEUED
[   22.228051] ata4.00: cmd 60/00:50:88:3d:a0/01:00:21:00:00/40 tag 10 ncq dma 131072 in
[   22.228051]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   22.244117] ata4.00: status: { DRDY ERR }
[   22.248132] ata4.00: error: { UNC }
[   22.257349] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
cannot import 'rpool': one or more devices is currently unavailable
cannot open 'rpool/local/transient/root@blank': dataset does not exist
importing root ZFS pool "rpool"...[   24.929374] ata4.00: exception Emask 0x0 SAct 0x30200 SErr 0x0 action 0x0
[   24.936175] ata4.00: irq_stat 0x40000008
[   24.940105] ata4.00: failed command: READ FPDMA QUEUED
[   24.945242] ata4.00: cmd 60/00:80:88:3d:a0/01:00:21:00:00/40 tag 16 ncq dma 131072 in
[   24.945242]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   24.961310] ata4.00: status: { DRDY ERR }
[   24.965322] ata4.00: error: { UNC }
[   24.973793] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x700 phys_seg 2 prio class 0
[   26.962353] ata4.00: exception Emask 0x0 SAct 0x20000 SErr 0x0 action 0x0
[   26.969153] ata4.00: irq_stat 0x40000008
[   26.973081] ata4.00: failed command: READ FPDMA QUEUED
[   26.978218] ata4.00: cmd 60/00:88:88:3d:a0/01:00:21:00:00/40 tag 17 ncq dma 131072 in
[   26.978218]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   26.994284] ata4.00: status: { DRDY ERR }
[   26.998299] ata4.00: error: { UNC }
[   27.007469] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
[   29.429376] ata4.00: exception Emask 0x0 SAct 0x10102 SErr 0x0 action 0x0
[   29.436178] ata4.00: irq_stat 0x40000008
[   29.440107] ata4.00: failed command: READ FPDMA QUEUED
[   29.445244] ata4.00: cmd 60/00:40:88:3d:a0/01:00:21:00:00/40 tag 8 ncq dma 131072 in
[   29.445244]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   29.461226] ata4.00: status: { DRDY ERR }
[   29.465238] ata4.00: error: { UNC }
[   29.474515] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x700 phys_seg 2 prio class 0
[   31.487404] ata4.00: exception Emask 0x0 SAct 0x20 SErr 0x0 action 0x0
[   31.493942] ata4.00: irq_stat 0x40000008
[   31.497870] ata4.00: failed command: READ FPDMA QUEUED
[   31.503006] ata4.00: cmd 60/00:28:88:3d:a0/01:00:21:00:00/40 tag 5 ncq dma 131072 in
[   31.503006]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   31.518988] ata4.00: status: { DRDY ERR }
[   31.523001] ata4.00: error: { UNC }
[   31.531482] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
[   33.945418] ata4.00: exception Emask 0x0 SAct 0x8 SErr 0x0 action 0x0
[   33.951869] ata4.00: irq_stat 0x40000008
[   33.955797] ata4.00: failed command: READ FPDMA QUEUED
[   33.960934] ata4.00: cmd 60/00:18:88:3d:a0/01:00:21:00:00/40 tag 3 ncq dma 131072 in
[   33.960934]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   33.976916] ata4.00: status: { DRDY ERR }
[   33.980928] ata4.00: error: { UNC }
[   33.990181] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x700 phys_seg 2 prio class 0
[   35.954361] ata4.00: exception Emask 0x0 SAct 0x10000000 SErr 0x0 action 0x0
[   35.961416] ata4.00: irq_stat 0x40000008
[   35.965346] ata4.00: failed command: READ FPDMA QUEUED
[   35.970483] ata4.00: cmd 60/00:e0:88:3d:a0/01:00:21:00:00/40 tag 28 ncq dma 131072 in
[   35.970483]          res 41/40:00:9d:3d:a0/00:00:21:00:00/40 Emask 0x409 (media error) <F>
[   35.986550] ata4.00: status: { DRDY ERR }
[   35.990563] ata4.00: error: { UNC }
[   35.999054] blk_update_request: I/O error, dev sdc, sector 564149661 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
```
