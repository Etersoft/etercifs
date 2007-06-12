#!/bin/sh
# Author: Vitaly Lipatov <lav@etersoft.ru>
# 2006, Public domain
# Release script for small projects packaged in RPM
# Use etersoft-build-utils as helper
. /etc/rpm/etersoft-build-functions

WORKDIR=~/Projects/eterbuild/functions
test -f $WORKDIR/config.in && . $WORKDIR/config.in

check_key

# Override spec's version
#TARBALLVERSION=1.6

update_from_cvs

SPECNAME=linux-cifs.spec
prepare_tarball


build_rpms_name $SPECNAME
test -z "$BASENAME" && fatal "BASENAME is empty"
#NAMEVER=$BASENAME-$VERSION

rpmbb $SPECNAME || fatal "Can't build"

if [ -n "$WINEPUB_PATH" -a $USER = "lav" ] ; then
	# Path to local publishing
	ETERDESTSRPM=$WINEPUB_PATH/sources
	cp -f $RPMSOURCEDIR/$TARNAME $ETERDESTSRPM/tarball/
	publish_srpm
fi

#OTNAME=$RPMSOURCEDIR/$TARNAME
# Usual path to public sources
# scp $TARNAME cf.sf:~   (use below params for it)
#PUBLICSERVER=etersoft
#PUBLICPATH=/home/lav/download/$BASENAME

#publish_tarball

#cd gentoo
#./release_port.sh
#cd -
