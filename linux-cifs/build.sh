#!/bin/sh
# 2006, 2007 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# Build kernel modules for all kernel and all platforms

. ./functions.sh

echo "All kernel build script. (c) 2007 Etersoft. $Id: build.sh,v 1.16 2007/06/14 14:55:14 lav Exp $"
PACKNAME=linux-cifs

get_src_dir || fatal "Distro $($DISTR_VENDOR -e) is not supported yet"

BUILDDIR=`pwd`/cifs-bld-tmp/fs/cifs
BUILTLIST=

# SMP build
[ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
[ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

detect_kernel()
{
	# Detect kernel version
	if [ -f $KERNEL_SOURCE/.kernelrelease ] ; then
		KERNELVERSION=`head -n 1 $KERNEL_SOURCE/.kernelrelease`
	elif [ -f $KERNEL_SOURCE/include/config/kernel.release ] ; then
		KERNELVERSION=`head -n 1 $KERNEL_SOURCE/include/config/kernel.release`
	elif [ -f $KERNEL_SOURCE/include/linux/version.h ] ; then
		KERNELVERSION=`head -n 1 $KERNEL_SOURCE/include/linux/version.h | grep UTS_RELEASE | cut -d" " -f 3 | sed -e 's|"||g'`
	fi
	if [ -z "$KERNELVERSION" ] ; then
		head -n 5 $KERNEL_SOURCE/Makefile | sed -e "s| ||g" >get_version
		. ./get_version
		KERNELVERSION=$VERSION.$PATCHLEVEL.$SUBLEVEL$EXTRAVERSION
		# Hack for strange SUSE 10.2
		if [ -z "$EXTRAVERSION" ] ; then
			KERNELVERSION=`grep KERNELSRC $KERNEL_SOURCE/Makefile | head -n 1 | sed -e "s|.*linux-||g"`
			[ -n "$KERNELVERSION" ] && KERNELVERSION=$KERNELVERSION-`basename $KERNEL_SOURCE`
		fi
	fi
}

echo "Install sources to $SBIN_DIR/../src/linux-cifs/"
install -m755 -d $SBIN_DIR/../src/linux-cifs/
install -m644 $BUILDDIR/* $SBIN_DIR/../src/linux-cifs/ || exit 1
install -m644 buildmodule.sh $SBIN_DIR/../src/linux-cifs/ || exit 1

for KERNEL_SOURCE in `echo $BASE_KERNEL_SOURCES_DIR` ; do
	[ -L $KERNEL_SOURCE ] && continue
	#[ -f $KERNEL_SOURCE/Makefile ] || continue
	# .config in Linux 2.6 only?
	[ -f $KERNEL_SOURCE/.config ] || continue
	echo
	echo "================================================================="
	# set GCC version if needed
	test -f $KERNEL_SOURCE/gcc_version.inc && . $KERNEL_SOURCE/gcc_version.inc && echo "Use GCC $GCC_VERSION" && export USEGCC="CC=gcc-$GCC_VERSION"

	#make CC=gcc$GCC_VERSION KERNSRC=$KERNEL_SOURCE kernel$KERNEL_VERSION

	detect_kernel
	echo "Build for $KERNEL_SOURCE (detected as $KERNELVERSION)"
	if [ -z "$KERNELVERSION" ] ; then
		fatal "Can't detect kernel version in $KERNEL_SOURCE"
	fi
	BUILTLIST="$BUILTLIST $KERNELVERSION"
	KERVER=$(echo $KERNELVERSION | cut -b 1-3)


	# Clean, build and check
	make $USEGCC -C $KERNEL_SOURCE here=$BUILDDIR SUBDIRS=$BUILDDIR clean
	make $USEGCC -C $KERNEL_SOURCE here=$BUILDDIR SUBDIRS=$BUILDDIR modules $MAKESMP
	MODULENAME=cifs
	#[ "$KERVER" = "2.4" ] && MODULENAME=$(echo $MODULENAME.o) || MODULENAME=$(echo $MODULENAME.?o)
	[ "$KERVER" = "2.4" ] && MODULENAME=$MODULENAME.o || MODULENAME=$MODULENAME.ko
	test -r "$BUILDDIR/$MODULENAME" || { echo "can't locate built module $MODULENAME, continue" ; continue ; }
	#echo "$KERNELVERSION $MODULENAME to $INSTALL_MOD_PATH"
	strip --strip-debug --discard-all $BUILDDIR/$MODULENAME

	mkdir -p $INSTALL_MOD_PATH/$KERNELVERSION/ || fatal "broken path"
	cp -fv $BUILDDIR/$MODULENAME $INSTALL_MOD_PATH/$KERNELVERSION/ || fatal "copy error"
	# copy last as default
	#cp -f $BUILDDIR/$MODULENAME $INSTALL_MOD_PATH/$PACKNAME/
	#make -C $KERNEL_SOURCE here=`pwd`/ SUBDIRS=`pwd`/ modules_install
	BUILTLIST="$BUILTLIST---DONE"
done
#cd -
test -z "$BUILTLIST" && fatal "build nothing"
echo
echo "========================================================================"
echo "CIFS Linux kernel module built for follow kernels (marked as ---DONE):"
for i in $BUILTLIST ; do echo -e "\t$i" ; done
echo
mkdir -p $SBIN_DIR $INIT_DIR
#install -m755 linux-cifs_depmod.sh $INSTALL_MOD_PATH/$PACKNAME/

install -m755 -D $PACKNAME.init $INIT_DIR/$PACKNAME
install -m755 $PACKNAME.outformat $INIT_DIR/


exit 0
