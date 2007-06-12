#!/bin/sh

# Build kernel module in installed system

MODULENAME=cifs.ko
BUILDDIR=/usr/src/linux-cifs
KERNELVERSION=$(uname -r)

[ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
[ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

echo 
echo "Build for $KERNELVERSION Linux kernel"
# source and destination directories can be inherited from the environment

if [ -z "$KERNSRC" ]; then
	KERNSRC=/lib/modules/$KERNELVERSION/build
fi
if [ -z "$INSTALL_MOD_PATH" ]; then
	#INSTALL_MOD_PATH=/lib/modules/$KERNELVERSION/kernel/extra
	INSTALL_MOD_PATH=/lib/modules/linux-cifs/$KERNELVERSION
fi

if [ ! -f $KERNSRC/include/linux/version.h ]; then
	cat 1>^2 <<EOF
Error: no kernel headers found at $KERNSRC
Please install package
 	kernel-headers-modules-XXXX for ALT Linux
 	kernel-devel-XXXX for FCx / ASP Linux
 	kernel-source-stripped-XXXX for Mandriva 2007
 	linux-headers for Debian / Ubuntu
 	kernel-source-XXXX for SuSe
 	kernel-source-XXXX for Slackware / MOPSLinux
or use KERNSRC variable to set correct location
Exiting...
EOF
	exit 1
fi

# set GCC version if needed
test -f $KERNSRC/gcc_version.inc && . $KERNSRC/gcc_version.inc && echo "We in ALT Linux, use GCC $GCC_VERSION" && export USEGCC="CC=gcc-$GCC_VERSION"
rm -f $BUILDDIR/$MODULENAME

# Build and check
make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR modules $MAKESMP

#[ "$KERVER" = "2.4" ] && MODULENAME=$MODULENAME.o || MODULENAME=$MODULENAME.ko
test -r "$BUILDDIR/$MODULENAME" || { echo "can't locate built module $MODULENAME, continue" ; exit 1 ; }
strip --strip-debug --discard-all $BUILDDIR/$MODULENAME

echo "Copying built module to $INSTALL_MOD_PATH"
mkdir -p $INSTALL_MOD_PATH
install -m 644 -o root -g root $BUILDDIR/$MODULENAME $INSTALL_MOD_PATH/ || exit 1
#depmod -ae || exit 1
#echo "$MODULENAME build correctly"
exit 0
