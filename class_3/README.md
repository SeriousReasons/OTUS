# Файловые системы и LVM

## Работа с томами

- начальный вид
```
[root@lvm vagrant]# lsblk
NAME                MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda                   8:0    0  40G  0 disk
├─sda1                8:1    0   1M  0 part
├─sda2                8:2    0   1G  0 part /boot
└─sda3                8:3    0  39G  0 part
  └─vg_base-lv_base 253:1    0  39G  0 lvm  /
sdb                   8:16   0  10G  0 disk
sdc                   8:32   0   2G  0 disk
sdd                   8:48   0   1G  0 disk
sde                   8:64   0   1G  0 disk
```

- подготовливаю временный том для корневого каталога /
```
[root@lvm vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@lvm vagrant]# vgcreate vg_backup /dev/sdb
  Volume group "vg_backup" successfully created
[root@lvm vagrant]# lvcreate -n lv_backup -l +100%FREE /dev/vg_backup
  Logical volume "lv_backup" created.
```

- создаю файловую ситсему и монтирую том
```
[root@lvm vagrant]# mkfs.xfs /dev/vg_backup/lv_backup
meta-data=/dev/vg_backup/lv_backup isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/vg_backup/lv_backup /mnt
```

- копирую все данные с / раздела в /mnt
```
[root@lvm vagrant]# xfsdump -J - / | xfsrestore -J - /mnt
[root@lvm vagrant]# ls /mnt
bin   dev  home  lib64  mnt  proc  run   srv       sys  usr
boot  etc  lib   media  opt  root  sbin  swapfile  tmp  var
```

- переконфигурирую grub
```
[root@lvm vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm vagrant]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-1127.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1127.el7.x86_64.img
done
```

- обновляю образ initrd
```
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
> s/.img//g"` --force; done
...
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-1127.el7.x86_64.img' done ***
```

- после перезапуска машины убеждаюсь, что загрузился под новым рутом
```
[root@lvm vagrant]# lsblk
NAME                MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda                   8:0    0  40G  0 disk
├─sda1                8:1    0   1M  0 part
├─sda2                8:2    0   1G  0 part /boot
└─sda3                8:3    0  39G  0 part
  └─vg_base-lv_base 253:1    0  39G  0 lvm
sdb                   8:16   0  10G  0 disk
└─vg_backup-lv_backup 253:0  0  10G  0 lvm  /
sdc                   8:32   0   2G  0 disk
sdd                   8:48   0   1G  0 disk
sde                   8:64   0   1G  0 disk
```

- удаляю старый LV на 40G и создаю новый на 8G
```
[root@lvm vagrant]# lvremove /dev/vg_base/lv_base
 Logical volume "lv_base" successfully removed
[root@lvm vagrant]# lvcreate -n vg_base/lv_base -L 8G /dev/vg_base
 Wiping xfs signature on /dev/vg_base/lv_base.
 Logical volume "lv_base" created.
```

- выполняю те же команды, что и при создании логического диска для backup'а.

- без перезапуска сразу создаю зеркало
```
[root@lvm vagrant]# pvcreate /dev/sdc /dev/sdd
 Physical volume "/dev/sdc" successfully created.
 Physical volume "/dev/sdd" successfully created.
[root@lvm vagrant]# vgcreate vg_var /dev/sdc /dev/sdd
 Volume group "vg_var" successfully created
[root@lvm vagrant]# lvcreate -L 950M -m1 -n lv_var vg_var
 Rounding up size to full physical extent 952.00 MiB
 Logical volume "lv_var" created.
```

- создаю на нем файловую систему и перемещаю туда каталог /var
```
[root@lvm vagrant]# mkfs.ext4 /dev/vg_var/lv_var
 Writing superblocks and filesystem accounting information: done
[root@lvm vagrant]# mount /dev/vg_var/lv_var /mnt
[root@lvm vagrant]# cp -aR /var/* /mnt/ # rsync -avHPSAX /var/ /mnt/
```

- для подстраховки отдельно сохраняю изначальный каталог /var
```
[root@lvm vagrant]# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```

- монтирую новый каталог /var
```
[root@lvm vagrant]# umount /mnt
[root@lvm vagrant]# mount /dev/vg_var/lv_var /var
```

- дописываю строки в /etc/fstab для автоматического монтирования каталога /var
```
[root@lvm vagrant]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

- после перезагрузки удаляю временную VG
```
[root@lvm vagrant]# lvremove /dev/vg_backup/lv_backup
 Logical volume "lv_backup" successfully removed
[root@lvm vagrant]# vgremove /dev/vg_backup
 Volume group "vg_backup" successfully removed
[root@lvm vagrant]# pvremove /dev/sdb
 Labels on physical volume "/dev/sdb" successfully wiped.
```

- выделяю том под каталог /home аналогично как для каталога /var
```
[root@lvm vagrant]# lvcreate -n lvHome -L 2G /dev/vg_base
 Logical volume "lvHome" created.
[root@lvm vagrant]# mkfs.xfs /dev/vg_base/lvHome
[root@lvm vagrant]# mount /dev/vg_base/lvHome /mnt/
[root@lvm vagrant]# cp -aR /home/* /mnt/
[root@lvm vagrant]# rm -rf /home/*
[root@lvm vagrant]# umount /mnt
[root@lvm vagrant]# mount /dev/vg_base/lvHome /home/
```

- также дописываю в /etc/fstab для автоматического монтирования каталога /home
```
[root@lvm vagrant]# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

Генерирую файлы в каталоге /home/
```
[root@lvm vagrant]# touch /home/file{1..20}
```
- снимаю снапшот
```
[root@lvm vagrant]# lvcreate -L 100MB -s -n home_snap /dev/vg_base/lvHome
```

- удаляю часть файлов
```
[root@lvm vagrant]# rm -f /home/file{11..20}
```

- востановление со снапшота
```
[root@lvm vagrant]# umount /home
[root@lvm vagrant]# lvconvert --merge /dev/vg_base/home_snap
[root@lvm vagrant]# mount /home
```
