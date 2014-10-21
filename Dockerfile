FROM centos:centos7
MAINTAINER Naoto ISHIKAWA <toona@toona.org>

# change yum repos
RUN cd /etc/yum.repos.d && \
    sed -i 's,mirror\.centos\.org/centos/,ftp.sakura.ad.jp/pub/linux/centos/,g' *.repo && \
    sed -i 's/^mirrorlist/#mirrorlist/g; s/^#baseurl/baseurl/g' *.repo && \
    yum -y clean all && \
    echo OK

# set timezone
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock && \
    rm -f /etc/localtime && \
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo OK

# fix sudoers
RUN yum install -y sudo && \
    sed -i 's,Defaults *requiretty,#Defaults    requiretty,g'  /etc/sudoers && \
    sed -i 's,Defaults\( *requiretty\),#Defaults\1,g'  /etc/sudoers && \
    sed -i 's,Defaults\( *secure_path.*\),#Defaults\1,g' /etc/sudoers && \
    sed -i 's,^\(\%wheel.*\),# \1,g' /etc/sudoers && \
    sed -i 's,^\# \(\%wheel.*NOPASSWD:.*\),\1,g' /etc/sudoers && \
    echo 'Defaults    env_keep += "PATH"' >> /etc/sudoers && \
    echo OK

# ssh
RUN yum install -y openssh-clients  openssh-server && \
    ssh-keygen -P "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -P "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    sed -i 's,\(^session *required *pam_loginuid.so\),#\1,' /etc/pam.d/sshd && \
    echo OK

# install apps via yum
RUN yum install -y bc bzip2 file gcc gcc-c++ gettext git man patch patchutils rsync strace unzip wget \
    witch yum-plugin-security yum-utils zip gdb libstdc++-devel libxml2 tar ntp emacs-nox telnet nc zsh libtiff \
    freetype libpng fontconfig libX11 libhugetlbfs libXpm gd  git make hostname screen open-ssl \
    bash geoip bind-utils expat-devel java && \
    yum install -y --enablerepo=centosplus openssl-devel && \
    rpm -Uvh ftp://fr.rpmfind.net/linux/fedora/linux/releases/19/Everything/x86_64/os/Packages/c/cmigemo-1.3-0.10.date20110227.fc19.1.x86_64.rpm && \
    echo OK

# install apps
ADD setup /root/setup

ADD setup/djb /root/setup/djb
RUN groupadd -g 189 logadmin && \
    adduser -u189 -g189 logadmin -s /sbin/nologin && \ 
    echo ">> SETUP daemontools"    && \
    cd /root/setup/djb/daemontools && sh install.sh > /dev/null 2>&1 && \
    echo ">> SETUP ucspi"          && \
    cd /root/setup/djb/ucspi       && sh install.sh > /dev/null 2>&1 && \
    echo ">> SETUP qmail"          && \
    cd /root/setup/djb/qmail       && sh install.sh > /dev/null 2>&1 && \
    cd /service && \
    ln -s /var/qmail/supervise/qmail-send  && \
    ln -s /var/qmail/supervise/qmail-smtpd && \
    echo ">> SETUP vpopmail"       && \
    cd /root/setup/djb/vpopmail    && sh install.sh > /dev/null 2>&1 && \
    echo ">> SETUP djbdns"         && \
    cd /root/setup/djb/djbdns      && sh install.sh > /dev/null 2>&1 && \
    echo OK
    # cd /service && \
    # ln -s /home/dns/dnscache .dnscache && \
    # ln -s /home/dns/tinydns  .tinydns  && \  

#     cd /usr/local/bin          && ln -s /usr/local/perl-5.20/bin/perl && \
#     curl -LOk http://xrl.us/cpanm && chmod +x cpanm && \
#     perl -i -nlpe 's,^\#\!.*,#!/usr/local/perl-5.20/bin/perl,g' cpanm && \
#     /usr/local/bin/cpanm install --mirror ftp://ftp.sakura.ad.jp/pub/lang/perl/CPAN/ --notest Carton > /dev/null 2>&1 && \
ADD setup/perl-5.20 /root/setup/perl-5.20
RUN echo ">> SETUP perl-5.20 with Carton" && \
    cd /root/setup/perl-5.20              && \
    tar zxf perl-5.20-Carton.tar.gz       && mv perl-5.20 /usr/local/.  && \
    cd /usr/local/bin && \
    ln -s /usr/local/perl-5.20/bin/perl && \
    ln -s /usr/local/perl-5.20/bin/perldoc && \
    ln -s /usr/local/perl-5.20/bin/cpanm   && \
    ln -s /usr/local/perl-5.20/bin/carton  && \
    perl -i -nlpe 's,^\#\!.*,#!/usr/local/perl-5.20/bin/perl,g' cpanm  && \
    perl -i -nlpe 's,^\#\!.*,#!/usr/local/perl-5.20/bin/perl,g' carton && \
    echo OK

# setup /service/sshd 
RUN mkdir -p /service/sshd/log && \
    echo -e '#!/bin/sh\nPATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\nexport PATH\nSSH_PORT=8022\ntcprules allow.cdb allow.tmp < allow\nexec env - PATH=$PATH  tcpserver -HRDl0 -x allow.cdb -u 0 0 $SSH_PORT sshd -i -e  2>&1' > /service/sshd/run && \
    echo -e '#!/bin/sh\nexec setuidgid logadmin multilog t s1000000 n100 ./main \n' > /service/sshd/log/run && \
    chmod +x /service/sshd/run /service/sshd/log/run && \
    chown logadmin:logadmin /service/sshd/log && \
    echo -e "127.0.0.1:allow\n192.168.:allow\n172.16.:allow\n172.17.:allow\n10.:allow\n:deny"  > /service/sshd/allow && \
    echo OK

# setup ~seesaa
RUN rm -fr /home/seesaa &&  \
    groupadd -g 500 seesaa && \
    adduser  -u 500 -g 500 seesaa -s /bin/zsh && \    
    cd ~seesaa && \
    chmod 755 . && \
    sudo -u seesaa ln -s /var/seesaa var && \
    sudo -u seesaa ln -s var/src  && \
    sudo -u seesaa ln -s src/file3x  && \
    sudo -u seesaa ln -s src/savacan && \
    sudo -u seesaa ln -s var/cpan && \
    echo OK

# setup ~toona
RUN groupadd -g 502 toona && \
    adduser  -u 502 -g 502 toona -s /bin/zsh && \
    cd ~toona && \
    mkdir .ssh && \   
    echo -e 'Host *\n\tServerAliveInterval 15\nHost github.com\n\tStrictHostKeyChecking no\n' > ~toona/.ssh/config && \
    chown toona:toona -R ~toona/.ssh && chmod -R 700 ~toona/.ssh && \
    sudo -u toona ln -s /var/seesaa var && \
    sudo -u toona ln -s var/src  && \
    rm -f .emacs && \
    sudo -u toona -H git clone https://github.com/naoto43/dot-files.git .dot-files && \
    for x in `ls .dot-files |grep dot | sed -e 's,dot-,,g'`; do rm -fr .$x ; sudo -u toona ln -s .dot-files/dot-$x .$x; done && \
    for x in id_rsa id_dsa authorized_keys; do sudo -u toona ln -s ~toona/var/.ssh/$x ~toona/.ssh/$x ; done && \
    perl -i -nlpe 's,(wheel:x:\d+?:),$1toona,g' /etc/group && \
    echo OK

EXPOSE 8022

CMD ["/usr/local/bin/svscanboot"]

# bug?
RUN chmod 777 /var/run/screen && \
    echo OK

