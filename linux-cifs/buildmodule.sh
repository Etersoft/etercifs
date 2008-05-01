#!/bin/sh
# 2007 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# Build kernel module in installed system

MODULEFILENAME=etercifs.ko
BUILDDIR=$(pwd)
KERNELVERSION=$(uname -r)

# SMP build
[ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
[ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

# source and destination directories can be inherited from the environment

if [ -z "$KERNSRC" ]; then
	KERNSRC=/lib/modules/$KERNELVERSION/build
fi
if [ -z "$INSTALL_MOD_PATH" ]; then
	INSTALL_MOD_PATH=/lib/modules/$KERNELVERSION/kernel/fs/cifs
	#INSTALL_MOD_PATH=/lib/modules/linux-cifs
fi

echo 
echo "Build for $KERNELVERSION Linux kernel (headers in $KERNSRC)"

if [ ! -f $KERNSRC/include/linux/version.h ]; then
	cat >&2 <<EOF
Error: no kernel headers found at $KERNSRC
Please install package
 	kernel-headers-modules-XXXX for ALT Linux
 	kernel-XXXX-devel for FCx / ASP Linux
 	dkms-linux-cifs for Mandriva 2008
 	linux-headers-XXXX for Debian / Ubuntu
 	kernel-source-XXXX for SuSe
 	kernel-source-XXXX for Slackware / MOPSLinux
or use KERNSRC variable to set correct location
Exiting...
EOF
	exit 1
fi

# set GCC version if needed
if [ -f $KERNSRC/gcc_version.inc ] ; then
	. $KERNSRC/gcc_version.inc
	echo "We in ALT Linux, use GCC $GCC_VERSION"
	export GCCNAME=gcc-$GCC_VERSION
	export USEGCC="CC=$GCCNAME"
else
	export GCCNAME=gcc
fi

if ! which $GCCNAME ; then
	echo "GCC compiler have not found. Please install gcc package."
	exit 1
fi

# Clean, build and check
rm -f $BUILDDIR/$MODULEFILENAME
make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR clean
make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR modules $MAKESMP

#[ "$KERVER" = "2.4" ] && MODULENAME=$MODULENAME.o || MODULENAME=$MODULENAME.ko
test -r "$BUILDDIR/$MODULEFILENAME" || { echo "can't locate built module $MODULEFILENAME, continue" ; exit 1 ; }
strip --strip-debug --discard-all $BUILDDIR/$MODULEFILENAME

echo "Copying built module to $INSTALL_MOD_PATH"
mkdir -p $INSTALL_MOD_PATH
install -m 644 -o root -g root $BUILDDIR/$MODULEFILENAME $INSTALL_MOD_PATH/ || exit 1
depmod -ae || exit 1
#echo "$MODULENAME build correctly"
exit 0
