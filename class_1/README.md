-----Command listing-----

sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

sudo rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

yum list available --disablerepo='*' --enablerepo=elrepo-kernel

sudo yum --enablerepo=elrepo-kernel install kernel-ml

reboot
