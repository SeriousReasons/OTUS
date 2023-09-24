# С чего начинается Linux


## Устанавливаем ключ GPG для репозитория ELRepo

sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org


## Устанавливаем репозиторий ELRepo

sudo rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm


## Выводим список доступных ядер

yum list available --disablerepo='*' --enablerepo=elrepo-kernel


## Устанавливаем последнюю доступную версию ядра

sudo yum --enablerepo=elrepo-kernel install kernel-ml


## Перезапускаем систему, чтобы изменения вступили в силу

reboot
