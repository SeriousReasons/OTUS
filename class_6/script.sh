        #!/bin/bash

        yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc gperftools-devel

        wget https://nginx.org/packages/mainline/centos/7/SRPMS/nginx-1.11.0-1.el7.ngx.src.rpm
        sudo -u vagrant rpm -i nginx-1.11.0-1.el7.ngx.src.rpm
        yum-builddep -y rpmbuild/SPECS/nginx.spec

        sed -i '/--with-ipv6/a \        --with-google_perftools_module \\' rpmbuild/SPECS/nginx.spec
        sed -i 's/worker_processes  1;/worker_processes  auto;/' rpmbuild/SOURCES/nginx.conf

        sudo -u vagrant rpmbuild -bb rpmbuild/SPECS/nginx.spec

        yum localinstall -y /home/vagrant/rpmbuild/RPMS/x86_64/nginx-1.11.0-1.el7.ngx.x86_64.rpm
        sed -i '/index  index.html/a \        autoindex on;' /etc/nginx/conf.d/default.conf
        systemctl start nginx
        systemctl status nginx

        mkdir /usr/share/nginx/html/repo
        mv /home/vagrant/rpmbuild/RPMS/x86_64/nginx-1.11.0-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/nginx-custom.ngx.x86_64.rpm
        createrepo /usr/share/nginx/html/repo/ 

        echo -e "[vagrant]\nname=vagrant-linux\nbaseurl=http://localhost/repo\ngpgcheck=0\nenabled=1" >> /etc/yum.repos.d/vagrant.repo