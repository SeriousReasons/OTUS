# Дисковая подсистема

## Подключение дополнительных дисков

- добавляю в vagrantfile дополнительные диски
```
          :sata5 => {
            :dfile => './sata5.vdi',
            :size => 500,
            :port => 5
          },
          :sata56 => {
            :dfile => './sata6.vdi',
            :size => 500,
            :port => 6
          }
```
## Создание RAID массива

- проверяю подключены ли новые диски
```
[vagrant@otuslinux ~]$ sudo lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  500M  0 disk
sdc      8:32   0  500M  0 disk
sdd      8:48   0  500M  0 disk
sde      8:64   0  500M  0 disk
sdf      8:80   0  500M  0 disk
sdg      8:96   0  500M  0 disk
```

- на всякий случай зануляю суперблоки на неразмеченных дисках
```
[vagrant@otuslinux ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
mdadm: Unrecognised md component device - /dev/sdg
```

- создаю RAID 5
```
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 5 -n 6 /dev/sd{b,c,d,e,f,g}
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 509952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

- проверяю, что RAID массив создан корректно
```
[vagrant@otuslinux ~]$ sudo mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri Oct 20 11:51:58 2023
        Raid Level : raid5
        Array Size : 2549760 (2.43 GiB 2.61 GB)
     Used Dev Size : 509952 (498.00 MiB 522.19 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Fri Oct 20 11:52:02 2023
             State : clean
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : ce784e83:2dc5ad9b:876b1046:e049d026
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
       6       8       96        5      active sync   /dev/sdg
```

- создаю mdadm.conf для автосборки RAID массива
```
[vagrant@otuslinux ~]$ sudo su
[root@otuslinux ~]$ mkdir /etc/mdadm
[root@otuslinux vagrant]# echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
[root@otuslinux vagrant]# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
[root@otuslinux vagrant]# cat /etc/mdadm/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid5 num-devices=6 metadata=1.2 name=otuslinux:0 UUID=ce784e83:2dc5ad9b:876b1046:e049d026
```

- искусственно ломаю RAID массив
```
[vagrant@otuslinux]# mdadm /dev/md0 --fail /dev/sdg
 sudo mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri Oct 20 11:51:58 2023
        Raid Level : raid5
        Array Size : 2549760 (2.43 GiB 2.61 GB)
     Used Dev Size : 509952 (498.00 MiB 522.19 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Fri Oct 20 12:02:21 2023
             State : clean, degraded
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : ce784e83:2dc5ad9b:876b1046:e049d026
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
       -       0        0        5      removed

       6       8       96        -      faulty   /dev/sdg
```

- востанавливаю RAID массив
```
[vagrant@otuslinux ~]$ sudo mdadm --remove /dev/md0 /dev/sdg
mdadm: hot removed /dev/sdg from /dev/md0
[vagrant@otuslinux ~]$ sudo mdadm --add /dev/md0 /dev/sdg
mdadm: added /dev/sdg
```
после ребилда
```
[vagrant@otuslinux ~]$ sudo mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri Oct 20 11:51:58 2023
        Raid Level : raid5
        Array Size : 2549760 (2.43 GiB 2.61 GB)
     Used Dev Size : 509952 (498.00 MiB 522.19 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Fri Oct 20 12:05:42 2023
             State : clean
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : ce784e83:2dc5ad9b:876b1046:e049d026
            Events : 40

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
       6       8       96        5      active sync   /dev/sdg
```

- размонтирую md0, чтобы создать GPT раздел с 4-мя партициями
```
[vagrant@otuslinux ~]$ sudo umount /dev/md0
[vagrant@otuslinux ~]$ sudo parted -s /dev/md0 mklabel gpt
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 0% 25%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 25% 50%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 50% 75%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 75% 100%
[vagrant@otuslinux ~]$ lsblk
NAME      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda         8:0    0    40G  0 disk
└─sda1      8:1    0    40G  0 part  /
sdb         8:16   0   500M  0 disk
└─md0       9:0    0   2.4G  0 raid5
  ├─md0p1 259:1    0   620M  0 md
  ├─md0p2 259:0    0 622.5M  0 md
  ├─md0p3 259:2    0 622.5M  0 md
  └─md0p4 259:3    0   620M  0 md
sdc         8:32   0   500M  0 disk
└─md0       9:0    0   2.4G  0 raid5
  ├─md0p1 259:1    0   620M  0 md
  ├─md0p2 259:0    0 622.5M  0 md
  ├─md0p3 259:2    0 622.5M  0 md
  └─md0p4 259:3    0   620M  0 md
sdd         8:48   0   500M  0 disk
└─md0       9:0    0   2.4G  0 raid5
  ├─md0p1 259:1    0   620M  0 md
  ├─md0p2 259:0    0 622.5M  0 md
  ├─md0p3 259:2    0 622.5M  0 md
  └─md0p4 259:3    0   620M  0 md
sde         8:64   0   500M  0 disk
└─md0       9:0    0   2.4G  0 raid5
  ├─md0p1 259:1    0   620M  0 md
  ├─md0p2 259:0    0 622.5M  0 md
  ├─md0p3 259:2    0 622.5M  0 md
  └─md0p4 259:3    0   620M  0 md
sdf         8:80   0   500M  0 disk
└─md0       9:0    0   2.4G  0 raid5
  ├─md0p1 259:1    0   620M  0 md
  ├─md0p2 259:0    0 622.5M  0 md
  ├─md0p3 259:2    0 622.5M  0 md
  └─md0p4 259:3    0   620M  0 md
sdg         8:96   0   500M  0 disk
└─md0       9:0    0   2.4G  0 raid5
  ├─md0p1 259:1    0   620M  0 md
  ├─md0p2 259:0    0 622.5M  0 md
  ├─md0p3 259:2    0 622.5M  0 md
  └─md0p4 259:3    0   620M  0 md
```
