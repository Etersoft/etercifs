#!/bin/sh
# 2007 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# modified: Konstantin Baev <kipruss@etersoft.ru>

# Build kernel modules for all kernel and all platforms

if [ -f /etc/etercifs.conf ] ; then
  . /etc/etercifs.conf
else
  fatal "Not found configuration file /etc/etercifs.conf"
fi

MODULEFILENAME=etercifs.ko
[ -n "$TESTBUILD" ] || TESTBUILD=0
[ -n "$DKMSBUILD" ] || DKMSBUILD=0

fatal()
{
    echo $@
    exit 1
}

exit_handler()
{
    local rc=$?
    trap - EXIT
    [ -z "$tmpdir" ] || rm -rf -- "$tmpdir"
    exit $rc
}

detect_etercifs_sources()
{
    [ -n "$ETERCIFS_SOURCES_LIST" ] || ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs*
    [ -n "`ls $ETERCIFS_SOURCES_LIST`" ] || fatal "Etercifs kernel module sources does not installed!"
    KERNEL_SOURCE_ETERCIFS_LINK=`ls -1 $ETERCIFS_SOURCES_LIST | grep $KERNEL | sort -r | head -n 1`
    KERNEL_SOURCE_ETERCIFS=`readlink -f $KERNEL_SOURCE_ETERCIFS_LINK`
    [ "$KERNEL_SOURCE_ETERCIFS" ] || fatal "Etercifs kernel module sources for current kernel does not installed!"
}

create_builddir()
{
    if [ -n "$BUILDDIR" ] ; then
        tmpdir=$BUILDDIR
    else
        tmpdir=
        tmpdir="$(mktemp -dt "Etercifs.XXXXXXXX")"
    fi
    tar -xjf $KERNEL_SOURCE_ETERCIFS -C $tmpdir
    trap exit_handler HUP PIPE INT QUIT TERM EXIT
    FILENAME=`basename $KERNEL_SOURCE_ETERCIFS`
    BUILDDIR=$tmpdir/${FILENAME%.tar.bz2}
}

kernel_release()
{
    KERNEL=`echo $KERNELVERSION | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/'`
}

# Heuristic
detect_kernel()
{
    # Detect kernel version
    if [ -f $KERNSRC/.kernelrelease ] ; then
        KERNELVERSION=`head -n 1 $KERNSRC/.kernelrelease`
    elif [ -f $KERNSRC/include/config/kernel.release ] ; then
        KERNELVERSION=`head -n 1 $KERNSRC/include/config/kernel.release`
    elif [ -f $KERNSRC/include/linux/version.h ] ; then
        KERNELVERSION=`head -n 1 $KERNSRC/include/linux/version.h | grep UTS_RELEASE | cut -d" " -f 3 | sed -e 's|"||g'`
    fi
    if [ -z "$KERNELVERSION" ] ; then
        head -n 5 $KERNSRC/Makefile | sed -e "s| ||g" >get_version
        . ./get_version
        KERNELVERSION=$VERSION.$PATCHLEVEL.$SUBLEVEL$EXTRAVERSION
        # Hack for strange SUSE 10.2
        if [ -z "$EXTRAVERSION" ] ; then
            KERNELVERSION=`grep KERNELSRC $KERNSRC/Makefile | head -n 1 | sed -e "s|.*linux-||g"`
            [ -n "$KERNELVERSION" ] && KERNELVERSION=$KERNELVERSION-`basename $KERNSRC`
        fi
    fi
    kernel_release
}

detect_host_kernel()
{
    [ -n "$KERNELVERSION" ] || KERNELVERSION=`uname -r`
    kernel_release

    if [ -z "$KERNSRC" ]; then
        KERNSRC=/lib/modules/$KERNELVERSION/build
    fi
}

check_headers()
{
    if [ ! -f $KERNSRC/include/linux/version.h ]; then
        cat >&2 <<EOF
Error: no kernel headers found at $KERNSRC
Please install package
    kernel-headers-modules-XXXX for ALT Linux
    kernel-XXXX-devel for FCx / ASP Linux
    dkms-etercifs for Mandriva 2009
    linux-headers-XXXX for Debian / Ubuntu
    kernel-source-XXXX for SuSe
    kernel-source-XXXX for Slackware / MOPSLinux
or use KERNSRC variable to set correct location
Exiting...
EOF
        exit 1
    fi
}

set_gcc()
{
    if [ -f $KERNSRC/gcc_version.inc ] ; then
        . $KERNSRC/gcc_version.inc
        if [ $TESTBUILD -ne 1 ] ; then
            echo "Use GCC $GCC_VERSION"
        fi
        export GCCNAME=gcc-$GCC_VERSION
        export USEGCC="CC=$GCCNAME"
    else
        export GCCNAME=gcc
    fi

    [ $TESTBUILD -eq 1 ] || echo `which $GCCNAME`
    if ! which $GCCNAME &>/dev/null ; then
        echo "GCC compiler have not found. Please install gcc package."
        exit 1
    fi
}

dkms_build_module()
{
    detect_etercifs_sources
    tar -xjf $KERNEL_SOURCE_ETERCIFS -C $SRC_DIR
    FILENAME=`basename $KERNEL_SOURCE_ETERCIFS`
    DIRNAME=${FILENAME%.tar.bz2}
    mv -f $SRC_DIR/$DIRNAME/* $SRC_DIR
    rm -rf $SRC_DIR/$DIRNAME
    dkms uninstall -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    dkms build -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    dkms install -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
}

compile_module()
{
    detect_etercifs_sources
    create_builddir
    check_headers
    set_gcc

    # SMP build
    [ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
    [ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

    # Clean, build and check
    #rm -f $BUILDDIR/$MODULEFILENAME
    if [ $TESTBUILD -eq 1 ] ; then
        make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR clean &>/dev/null
        make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR modules $MAKESMP &>/dev/null
    else
        make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR clean
        make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR modules $MAKESMP
    fi
}

install_module()
{
    if [ -z "$INSTALL_MOD_PATH" ]; then
        INSTALL_MOD_PATH=/lib/modules/$KERNELVERSION/kernel/fs/cifs
    fi
    test -r "$BUILDDIR/$MODULEFILENAME" || { echo "can't locate built module $MODULEFILENAME" ; exit 1 ; }
    strip --strip-debug --discard-all $BUILDDIR/$MODULEFILENAME
    echo "Copying built module to $INSTALL_MOD_PATH"

    mkdir -p $INSTALL_MOD_PATH
    install -m 644 -o root -g root $BUILDDIR/$MODULEFILENAME $INSTALL_MOD_PATH/ || exit 1
    depmod -ae || exit 1
}

check_build_module()
{
    if [ -r "$BUILDDIR/$MODULEFILENAME" ] ; then
        echo "$KERNELVERSION - OK"
        BUILTLIST="$BUILTLIST---DONE"
    else
        echo "can't locate built module $MODULEFILENAME"
        echo "$KERNELVERSION - FAIL"
    fi
}

