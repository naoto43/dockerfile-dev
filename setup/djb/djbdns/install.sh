#/bin/sh

useradd -u 8853            -d /home/dns      -s /sbin/nologin dns
mkdir -p /home/dns
chown dns:dns /home/dns

FILE_DNS=djbdns-1.05
tar xfvz $FILE_DNS.tar.gz

# ----
# djbdns
# ----
cd $FILE_DNS
patch -p1 < ../patch/djbdns-for-redhat9.patch
patch -p1 < ../patch/increase_query_loop.patch
make && make setup check

./dnscache-conf dns logadmin /home/dns/dnscache
cd -

# for settings
cp -r settings/* /home/dns/.
mkdir -p /home/dns/tinydns/log/main
mkdir -p /home/dns/dnscache/log/main
chown logadmin:logadmin /home/dns/tinydns/log/main
chown logadmin:logadmin /home/dns/dnscache/log/main

rm -fr $FILE_DNS
