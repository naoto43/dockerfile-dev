#!/bin/sh

FILE_UCSPI=ucspi-tcp-0.88
tar xfvz $FILE_UCSPI.tar.gz
cd $FILE_UCSPI
patch -p1 < ../patch/ucspi-for-redhat9.patch
make && make setup check
cd ..
rm -fr $FILE_UCSPI
