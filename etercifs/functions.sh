#!/bin/sh
# 2007-2010, 2017 (c) Etersoft http://etersoft.ru
# Vitaly Lipatov <lav@etersoft.ru>
# Konstantin Baev <kipruss@etersoft.ru>
# Pavel Shilovsky <piastry@etersoft.ru>
# Konstantin Artyushkin <akv@etersoft.ru>
# GNU Public License

# Build kernel modules for all kernel and all platforms


fatal()
{
    echo $@
    exit 1
}

[ -s "$PACKAGEINFO" ] || PACKAGEINFO=@DATADIR@/package.conf
if [ -f "$PACKAGEINFO" ] ; then
  . $PACKAGEINFO
else
  fatal "Not found package information file $PACKAGEINFO"
fi

ETERCIFS_SOURCES_TARBALL=$DATADIR/etercifs-sources-$MODULEVERSION.tar.xz

list_source_versions()
{
    tar --list --no-recursion -f $ETERCIFS_SOURCES_TARBALL --exclude '*/*' | sed -e "s|/||g"
}

# arg: version target
extract_source()
{
    mkdir -p "$2" || fatal
    tar -xJf $ETERCIFS_SOURCES_TARBALL -C "$2" --strip 1 "$1"
}

# TODO: drop it too
check_for_openvz()
{
    if echo "$KERNELVERSION" | egrep -q "2\.6\.18.*(stab|ovz-el|ovz-rhel)" ; then
        KERNEL_STRING="centos-ovz"
    elif echo "$KERNELVERSION" | egrep -q "2\.6\.32.*(stab|ovz-el|ovz-smp|ovz-rhel|openvz)" ; then
        KERNEL_STRING="centos60"
    else
        return 1
    fi
    return 0
}

# kernel version sorting
sort_dn()
{
    # sort -V
    sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4 -g "$@"
}

# build fake source table from source list
fake_source_versions()
{
    echo "[Generic]"
    list_source_versions | grep '^[0-9]' | sort_dn -r
}

detect_etercifs_sources()
{
    KERNEL_STRING=
    if check_for_openvz ; then
        echo "Building from legacy sources for OpenVZ kernel $KERNEL_STRING"
    elif which lsb_release > /dev/null; then
        # TODO epm
        DISTRO=$(lsb_release -d)
        KERNEL_STRING=$(./source.sh "$DISTRO" "$KERNELVERSION" < source.table)
    fi

    # generic kernels
    if [ -z "$KERNEL_STRING" ] || [ "$KERNEL_STRING" = "fixme" ] ; then
        KERNEL_STRING=$(fake_source_versions | ./source.sh "Generic" "$KERNELVERSION")
    fi

    if [ -n "$KERNEL_STRING" ] ; then
        echo "Building for $KERNEL_STRING kernel version"
    else
        echo "Can't locate any appropiate kernel sources for the kernel $KERNELVERSION"
        check_headers
        exit
    fi

    KERNEL_SOURCE_ETERCIFS="$KERNEL_STRING"

    # TODO: print info about strict version
    #LATEST_SOURCES=$(echo $KERNEL_SOURCE_ETERCIFS | cut -d"-" -f 4)
    #echo "Warning! Couldn't find module sources for the kernel $KERNEL!"
    #echo "Using the latest supported sources - from v$LATEST_SOURCES kernel!"

}

exit_handler()
{
    local rc=$?
    trap - EXIT
    if [ -n "$tmpdir" ] ; then
        rm -rf -- "$tmpdir"
        unset tmpdir
    fi
    exit $rc
}

# can be used with external BUILDDIR
create_builddir()
{
    if [ -n "$BUILDDIR" ] ; then
        tmpdir=$BUILDDIR
    else
        tmpdir=
        tmpdir="$(mktemp -dt "Etercifs.XXXXXXXX")"
        trap exit_handler HUP PIPE INT QUIT TERM EXIT
        BUILDDIR="$tmpdir/$KERNEL_SOURCE_ETERCIFS"
    fi
    extract_source "$KERNEL_SOURCE_ETERCIFS" "$BUILDDIR"
}

list_kernel_headers()
{
    local LM
    for LM in `ls -d /lib/modules/*/build` ; do
        [ -r "$LM" ] || continue
        [ -L $(readlink $LM) ] && continue
        [ -f $LM/.config ] || continue
        echo "$LM"
    done
}

check_headers()
{
    if [ ! -f $KERNSRC/include/linux/version.h ] && [ ! -f $KERNSRC/include/generated/uapi/linux/version.h ] ; then
# TODO: use distr_vendor
# TODO: use eepm, try install
        cat >&2 <<EOF
Error: no kernel headers found at $KERNSRC, there are follows only:
$(list_kernel_headers)

Please install follow package for the current kernel:
    kernel-headers-modules-XXXX for ALT Linux
    kernel-devel for RHEL / CentOS / Fedora
    linux-headers-XXXX for Debian / Ubuntu
    kernel-source-XXXX for SUSE Linux
    kernel-source-XXXX for Slackware
    dkms-etercifs for ROSA / Mandriva
where XXXX is your current kernel version from \$ uname -r ( $(uname -r) )
or set KERNSRC to set correct kernel headers location (/lib/modules/KERNELVERSION/build)
or set KERNELVERSION variable to set correct version (for /lib/modules/KERNELVERSION/build)
Exiting...
EOF
# FIXME: check detect
        return 1
    fi
}

set_gcc()
{
    if [ -f $KERNSRC/gcc_version.inc ] ; then
        . $KERNSRC/gcc_version.inc
        echo "Use GCC $GCC_VERSION from $KERNSRC/gcc_version.inc"
        export GCCNAME=gcc-$GCC_VERSION
        export USEGCC="CC=$GCCNAME"
    else
        export GCCNAME=gcc
    fi

    # TODO: epm assure make
    which make >/dev/null || fatal "GNU make utility have not found. Please, install make package."

    PATHGCC=`which $GCCNAME`
    [ $PATHGCC ] || fatal "GCC compiler have not found. Please, install gcc package."
    echo $PATHGCC
}

dkms_build_module()
{
    local DKMSOPTS=
    detect_etercifs_sources
    STATUS=`dkms status -m $MODULENAME -v $MODULEVERSION`
    [ "$STATUS" ] || a= dkms add -m $MODULENAME -v $MODULEVERSION
    BUILDDIR=$SRC_DIR
    create_builddir || fatal
    change_cifsversion
    [ -n "$KERNELMANUAL" ] && DKMSOPTS="-k $KERNELVERSION --kernelsourcedir=$KERNSRC"
    a= dkms uninstall $DKMSOPTS -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    a= dkms build $DKMSOPTS -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    a= dkms install $DKMSOPTS -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
}

# TODO: change it in the repo!
change_cifsversion()
{
    if [ -f $BUILDDIR/cifsfs.h ] ; then
        CIFSVERSION=`cat $BUILDDIR/cifsfs.h | grep CIFS_VERSION`
        CIFSVERSION=`echo $CIFSVERSION | sed 's|#define CIFS_VERSION||g'`
        CIFSVERSION=`echo $CIFSVERSION | sed 's|"||g'`
        CIFSVERSION=`echo $CIFSVERSION | sed 's| ||g'`
        sed -i "s/$CIFSVERSION/$MODULEVERSION/g" $BUILDDIR/cifsfs.h
        echo "Setting etercifs version: OK"
    else
        echo "Setting etercifs version: FAIL"
    fi
}

check_kernel_conf()
{
    echo "Checking the kernel configuration..."
    if [ -r "$KERNSRC/.config" ]; then
        CONF_STRING=`cat $KERNSRC/.config | grep CONFIG_CIFS=`
        CONF_LETTER=`echo $CONF_STRING | cut -b 13-13`
        case "$CONF_LETTER" in
            "m")
                echo "OK"
                ;;
            "y")
                echo "ERROR: the kernel is configured with CIFS support, but not as a module!"
                return 1
                ;;
            *)
                echo "ERROR: the kernel is configured without CIFS support!"
                return 1
        esac
    else
        echo "ERROR: the .config file in kernel source directory does not exist!"
        return 1
    fi
    return 0
}

compile_module()
{
    detect_etercifs_sources
    check_headers || return
    create_builddir || return
    set_gcc

    # SMP build
    [ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
    [ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

    check_kernel_conf || return

    change_cifsversion
    make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR clean
    make $USEGCC -C $KERNSRC here=$BUILDDIR SUBDIRS=$BUILDDIR modules $MAKESMP
}

install_module()
{
    if [ -z "$INSTALL_MOD_PATH" ]; then
        INSTALL_MOD_PATH=/lib/modules/$KERNELVERSION/kernel/fs/cifs
    fi
    test -r "$BUILDDIR/$MODULEFILENAME" || fatal "can't locate built module $MODULEFILENAME"
    echo "Stripping module $MODULEFILENAME ..."
    strip --strip-debug --discard-all $BUILDDIR/$MODULEFILENAME

    echo "Copying built module to $INSTALL_MOD_PATH"
    mkdir -p $INSTALL_MOD_PATH
    install -m 644 -o root -g root $BUILDDIR/$MODULEFILENAME $INSTALL_MOD_PATH/ || exit 1

    echo "Do depmod -Ae for $KERNELVERSION kernel"
    depmod -Ae $KERNELVERSION
}

