#!/bin/sh

. /etc/rpm/etersoft-build-functions

WORKDIR=/home/builder/Projects/eterbuild/functions

PORTNAME=linux-cifs

test -f $WORKDIR/config.in && . $WORKDIR/config.in

#check_key

update_from_cvs

WINENUMVERSION=current
TARNAME=gentoo-$PORTNAME.tar.bz2
TARPATH=$WINEPUB_PATH-$WINENUMVERSION/sources/$TARNAME
echo "Creating $TARPATH"
tar cvfj $TARPATH $PORTNAME/* --exclude CVS
