#!/bin/sh



# ===========================================
# config
# ===========================================
GET_COMMAND=wget

GET_FILE=perl-5.20.0

GET_URL=http://ftp.funet.fi/pub/CPAN/src/$GET_FILE.tar.gz

INSTALL_DATE=`date +%Y%m%d`
INSTALL_HOME=/usr/local/perl-5.14
ORG_RENAME=${INSTALL_HOME}_${_DATE}.$$


do_clean() {
    for var in $*
    do
        if [ -d $var ]
        then
            rm -iRf $var
        fi
    done
}



# ============================================
# initialization
# ============================================
do_clean $GET_FILE


if [ ! -f "${GET_FILE}.tar.gz" ]
then
    echo "${GET_FILE}.tar.gz"
    $GET_COMMAND $GET_URL
fi



# ============================================
# do task
# ============================================
tar xfvz $GET_FILE.tar.gz && \
cd $GET_FILE && \

# mkdir -p /home/seesaa/cpan/lib/site_perl

sh Configure -de -Accflags='-DAPPLLIB_EXP=\"/home/seesaa/project/lib:/home/seesaa/cpan/lib\"' -Dusethreads -Dprefix=/usr/local/perl-5.20

make && make install && \
cd .. && \
do_clean $GET_FILE && \
echo "all success."
