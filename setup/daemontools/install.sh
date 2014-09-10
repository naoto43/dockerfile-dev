#!/bin/sh

mkdir -p /root/tmp
export TMPDIR=/root/tmp
export PATH=$PATH:/usr/local/bin

mkdir -p  /package
chmod 755 /package
chmod +t  /package


FILE_DAEMON=daemontools-0.76
tar xfvz $FILE_DAEMON.tar.gz
cd admin/$FILE_DAEMON
patch -p2 < ../../patch/daemontools-for-redhat9.patch
patch -p1 < ../../patch/daemontools-0.76.sigq12.patch
cd - && mv admin /package/admin && cd /package/admin/$FILE_DAEMON
./package/install
cd - && cd /command
date | ./tai64n | ./tai64nlocal
date | sh -c './multilog t e 2>&1' | ./tai64nlocal

rm -fr $TMPDIR
