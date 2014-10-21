#!/bin/sh
PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin

groupadd -g 10000 vchkpw
useradd -u 10000 -g vchkpw -d /home/vpopmail -s /sbin/nologin vpopmail
useradd -u 9001            -d /dev/null      -s /sbin/nologin logadmin

MY_FQDN=localhost

mkdir -p /home/vpopmail/etc/
echo '127.:allow,RELAYCLIENT=""
192.168.:allow,RELAYCLIENT=""
' | tee /home/vpopmail/etc/tcp.smtp

echo $MY_FQDN | tee /home/vpopmail/etc/defaultdomain
/usr/local/bin/tcprules /home/vpopmail/etc/tcp.smtp.cdb /home/vpopmail/etc/tcp.smtp.tmp < /home/vpopmail/etc/tcp.smtp

FILE_VPOPMAIL=vpopmail-5.4.0
tar xfvz $FILE_VPOPMAIL.tar.gz
cd $FILE_VPOPMAIL && \
./configure \
    --enable-roaming-users=y \
    --enable-relay-clear-minutes=10 \
    --enable-tcpserver-file=/home/vpopmail/etc/tcp.smtp \
    --enable-logging=y
make && make install-strip
cd ..
rm -fr $FILE_VPOPMAIL


