#!/bin/sh
PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin

mkdir -p  /var/qmail

groupadd -g 181    nofiles
groupadd -g 182    qmail

useradd -u 181 -g nofiles -d /var/qmail/alias -s /sbin/nologin alias
useradd -u 182 -g nofiles -d /var/qmail       -s /sbin/nologin qmaild
useradd -u 183 -g nofiles -d /var/qmail       -s /sbin/nologin qmaill
useradd -u 184 -g nofiles -d /var/qmail       -s /sbin/nologin qmailp

useradd -u 185 -g qmail   -d /var/qmail       -s /sbin/nologin qmailq
useradd -u 186 -g qmail   -d /var/qmail       -s /sbin/nologin qmailr
useradd -u 187 -g qmail   -d /var/qmail       -s /sbin/nologin qmails

useradd -u 189 logadmin -s /sbin/nologin

MY_FQDN=localhost
FILE_QMAIL=qmail-1.03


tar xfvz $FILE_QMAIL.tar.gz

cd $FILE_QMAIL
patch -p1 < ../patch/qmail-for-redhat9.patch
##patch -p1 < ../patch/qmail-default-mailbox.patch
patch -p1 < ../patch/qmail-date-localtime.patch
patch -p1 < ../patch/qmail-date-localtime2.patch
patch -p1 < ../patch/qmail-smtpd-relay-reject.patch
#patch -p1 < ../patch/qmail-large-dns.patch
#patch -p1 < ../patch/qmail-big-concurrency.patch
make setup 2>&1| tee install.log && make check
./config-fast $MY_FQDN
cd ..
rm -fr $FILE_QMAIL

cd /var/qmail
cp ./boot/home ./rc
touch alias/.qmail-postmaster alias/.qmail-mailer-daemon alias/.qmail-root
chmod 644 alias/.qmail* 


# settings

## qmail-send
mkdir -p /var/qmail/supervise/qmail-send
echo '#!/bin/sh

PATH=/var/qmail/bin:/usr/home/vpopmail/bin:/usr/local/bin:/usr/bin:/bin
export PATH

sleep 10

exec env - PATH=$PATH \
qmail-start ./Maildir/ 2>&1
' | tee /var/qmail/supervise/qmail-send/run && chmod +x /var/qmail/supervise/qmail-send/run

mkdir -p /var/qmail/supervise/qmail-send/log/main
echo '#!/bin/sh
exec setuidgid logadmin multilog t s1000000 n100 ./main
' | tee /var/qmail/supervise/qmail-send/log/run && chmod +x /var/qmail/supervise/qmail-send/log/run
chown -R logadmin:logadmin /var/qmail/supervise/qmail-send/log/main
#cd /service && ln -s /var/qmail/supervise/qmail-send qmail-send


## qmail-smtpd
mkdir /var/qmail/supervise/qmail-smtpd
echo '#!/bin/sh

PATH=/var/qmail/bin:/home/vpopmail/bin:/usr/local/bin:/usr/bin:/bin
export PATH

sleep 10

_rule=/home/vpopmail/etc/tcp.smtp.cdb

exec env - PATH=$PATH \
tcpserver -HRDlO -x $_rule -u qmaild -g nofiles 0 smtp \
qmail-smtpd 2>&1
' | tee /var/qmail/supervise/qmail-smtpd/run && chmod +x /var/qmail/supervise/qmail-smtpd/run

mkdir -p /var/qmail/supervise/qmail-smtpd/log/main
echo '#!/bin/sh
exec setuidgid logadmin multilog t s1000000 n100 ./main
' | tee /var/qmail/supervise/qmail-smtpd/log/run && chmod +x /var/qmail/supervise/qmail-smtpd/log/run
chown -R logadmin:logadmin /var/qmail/supervise/qmail-smtpd/log/main
#cd /service && ln -s /var/qmail/supervise/qmail-smtpd qmail-smtpd
