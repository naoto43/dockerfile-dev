FROM centos:centos7
MAINTAINER Naoto ISHIKAWA <toona@toona.org>


# change yum repos
RUN cd /etc/yum.repos.d && sed -i 's,mirror\.centos\.org/centos/,ftp.sakura.ad.jp/pub/linux/centos/,g' *.repo && sed -i 's/^mirrorlist/#mirrorlist/g; s/^#baseurl/baseurl/g' *.repo && yum -y clean all

# install apps via yum
RUN yum install -y bc bzip2 file gcc gcc-c++ gettext git man openssh-clients patch patchutils rsync strace unzip wget witch yum-plugin-security yum-utils zip gdb libstdc++-devel libxml2 tar sudo ntp emacs-nox telnet nc zsh libtiff freetype libpng fontconfig libX11 libhugetlbfs libXpm gd && yum install -y --enablerepo=centosplus openssl-devel git openssh-server make hostname screen

# install apps
ADD setup /root/setup
RUN cd /root/setup/daemontools && sh install.sh > /dev/null 2>&1 && \
    cd /root/setup/ucspi       && sh install.sh > /dev/null 2>&1 

# fix sudoers
RUN sed -i 's,Defaults *requiretty,#Defaults    requiretty,g'  /etc/sudoers && \
    sed -i 's,Defaults\( *requiretty\),#Defaults\1,g'  /etc/sudoers && \
    sed -i 's,Defaults\( *secure_path.*\),#Defaults\1,g' /etc/sudoers && \
    sed -i 's,^\(\%wheel.*\),# \1,g' /etc/sudoers && \
    sed -i 's,^\# \(\%wheel.*NOPASSWD:.*\),\1,g' /etc/sudoers && \
    echo 'Defaults    env_keep += "PATH"' >> /etc/sudoers

# set timezone
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock && rm -f /etc/localtime && ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# setup /service/sshd 
RUN adduser -u189 logadmin -s /sbin/nologin && \ 
    mkdir -p /service/sshd/log && \
    echo -e '#!/bin/sh\nPATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\nexport PATH\nSSH_PORT=8022\ntcprules allow.cdb allow.tmp < allow\nexec env - PATH=$PATH  tcpserver -HRDl0 -x allow.cdb -u 0 0 $SSH_PORT sshd -i -e  2>&1' > /service/sshd/run && \
    echo -e '#!/bin/sh\nexec setuidgid logadmin multilog t s1000000 n100 ./main \n' > /service/sshd/log/run && \
    chmod +x /service/sshd/run /service/sshd/log/run && chown logadmin:logadmin /service/sshd/log && \
    ssh-keygen -P "" -t rsa -f /etc/ssh/ssh_host_rsa_key && ssh-keygen -P "" -t dsa -f /etc/ssh/ssh_host_dsa_key && echo -e "127.0.0.1:allow\n192.168.:allow\n172.16.:allow\n172.17.:allow\n10.:allow\n:deny"  > /service/sshd/allow && sed -i 's,\(^session *required *pam_loginuid.so\),#\1,' /etc/pam.d/sshd

# setup ~toona
RUN groupadd -g 502 toona && \
    adduser  -u 502 -g 502 toona -s /bin/zsh && \
    cd ~toona && \
    mkdir .ssh && \   
    echo 'ssh-dss AAAAB3NzaC1kc3MAAACBAP1TLmw3x4inTcmKfW/8sOb8EeUs6pMxhl5/rzFsuh/p8wU3o8KVDeaHfCaxuiddMEUsZLYxMtmu7yFTDP/UKLLyOCM388/SUJBnlCT2HNQYk8IAjkV+649D3bEBDzR7kn08t2J9uoqf8Gn2OscFbeswUuQ78afViXSY8XdNgPArAAAAFQDMF/NW4FnFLMWOvLzpmG310BUuVwAAAIBzV6YclKZneyJhIkWv4xHV1DeRf3OAgyi6ulWq7fTRRU3bZOhImZwwkeSKmVPtzYIoQQtzSOTqPvH3lJerv3ErdA9ak98YpkkEIbWfvZJx4IEWTE8zjAc6Qjaa3MIGCgvRiEhJNbK1YzkkmJflxi3lUheiB7Wxr8G2JbpRYBqYlQAAAIEAlu+jOt/z2V/No53f3VmLSoCdC2tppZEA6N9ommf+yQfVS5eVpCG+n9sD6Yld/tWlBV4iVaunJlMMxSxj4ixKHNiw7+ankevc1g9Wmvbn3zs4gIyN2tpkI3FfWKWkWyGjFqhPQJuSivQGu4b0fXHcitGTnjfX50O/kOzEp/F9QfI= toona@toona.dev' > .ssh/authorized_keys && \
    echo -e 'Host *\n\tServerAliveInterval 15\nHost github.com\n\tStrictHostKeyChecking no\n' > ~toona/.ssh/config && \
    chown toona:toona -R ~toona/.ssh && chmod -R 700 ~toona/.ssh && \
    sudo -u toona ln -s /var/seesaa var && \
    sudo -u toona ln -s var/src  && \
    rm -f .emacs && \
    sudo -u toona -H git clone https://github.com/naoto43/dot-files.git .dot-files && \
    for x in `ls .dot-files |grep dot | sed -e 's,dot-,,g'`; do rm -fr .$x ; sudo -u toona ln -s .dot-files/dot-$x .$x; done && \
    for x in id_rsa id_dsa ; do sudo -u toona ln -s ~toona/var/.ssh/$x ~toona/.ssh/$x ; done && \
    perl -i -nlpe 's,(wheel:x:\d+?:),$1toona,g' /etc/group

EXPOSE 8022

RUN cd ~toona/.dot-files && sudo -u toona -H git pull

CMD ["/usr/local/bin/svscanboot"]
