#!/bin/sh
# 2007-2010 (c) Etersoft http://etersoft.ru
# Vitaly Lipatov <lav@etersoft.ru>
# Konstantin Baev <kipruss@etersoft.ru>
# Pavel Shilovsky <piastry@etersoft.ru>
# GNU Public License

# Build kernel modules for all kernel and all platforms

PACKAGEINFO=@DATADIR@/package.conf
if [ -f "$PACKAGEINFO" ] ; then
  . $PACKAGEINFO
else
  fatal "Not found package information file $PACKAGEINFO"
fi

CONFIGFILE=@SYSCONFIGDIR@/etercifs.conf
if [ -f $CONFIGFILE ] ; then
  . $CONFIGFILE
else
  fatal "Not found configuration file $CONFIGFILE"
fi


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

split_kernel_version()
{
    N1=`echo $KERNEL | cut -d"." -f 1`
    N2=`echo $KERNEL | cut -d"." -f 2`
    N3=`echo $KERNEL | cut -d"." -f 3 | cut -d"-" -f 1`
}

check_for_openvz()
{
    if echo "$KERNELVERSION" | egrep -q "2\.6\.18.*(stab|ovz-el|ovz-rhel)" ; then
        OVZ_KERNEL="centos-ovz"
    elif echo "$KERNELVERSION" | egrep -q "2\.6\.32.*(stab|ovz-el|ovz-smp|ovz-rhel|openvz)" ; then
        OVZ_KERNEL="centos60"
    else
        return 1
    fi
    return 0
}

check_for_centos()
{
    if which lsb_release > /dev/null; then
        lsb_release -d | egrep -q 'GosLinux|CentOS|Red Hat|Scientific Linux|NauLinux|LinuxWizard Server|RERemix' || return
    fi

        echo
        echo "Found RHEL-like distribution."

        kernel_release4
        N1=`echo $KERNEL4 | cut -d"." -f 1`
        N2=`echo $KERNEL4 | cut -d"." -f 2`
        N3=`echo $KERNEL4 | cut -d"." -f 3 | cut -d"-" -f 1`
        N4=`echo $KERNEL4 | cut -d"-" -f 2 | cut -d"." -f 1`

        CENTOS=0
        if [ "$N1" -eq 2 ] && [ "$N2" -eq 6 ] ; then
            if [ "$N3" -eq 18 ] ; then
                if [ "$N4" -eq 274 ] ; then
                    echo "Your kernel is 2.6.18-274.x"
                    CENTOS=57
                elif [ "$N4" -gt 274 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-274.x"
                    CENTOS=56
                elif [ "$N4" -eq 238 ] ; then
                    echo "Your kernel is 2.6.18-238.x"
                    CENTOS=56
                elif [ "$N4" -gt 238 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-238.x"
                    CENTOS=56
                elif [ "$N4" -eq 194 ] ; then
                    echo "Your kernel is 2.6.18-194.x"
                    CENTOS=55
                elif [ "$N4" -gt 194 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-194.x and older than 2.6.18.238.x"
                    CENTOS=55
                elif [ "$N4" -eq 164 ] ; then
                    echo "Your kernel is 2.6.18-164.x"
                    CENTOS=54
                elif [ "$N4" -gt 164 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-164.x and older than 2.6.18.194.x"
                    CENTOS=54
                elif [ "$N4" -eq 128 ] ; then
                    echo "Your kernel is 2.6.18-128.x"
                    CENTOS=53
                elif [ "$N4" -gt 128 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-128.x and older than 2.6.18-164.x"
                    CENTOS=53
                elif [ "$N4" -eq 92 ] ; then
                    echo "You kernel is 2.6.18-92.x"
                    CENTOS=52
                elif [ "$N4" -gt 92 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-92.x and older than 2.6.18-128.x"
                    CENTOS=52
                else
                    echo "Warning! Your kernel is older than 2.6.18-92.x"
                    CENTOS=52
                fi
            elif [ "$N3" -gt 18 ] && [ "$N3" -lt 23 ] ; then
                echo "Warning! Your kernel is newer than 2.6.18 and older than 2.6.23"
                CENTOS=53
            elif [ "$N3" -eq 32 ] ; then
                echo "Your kernel is 2.6.32-x.y"
                CENTOS=60
            else
                echo "Warning! Your kernel is older than 2.6.18 or newer than 2.6.23"
            fi
        elif [ "$N1" -eq 3 ] && [ "$N2" -eq 10 ] ; then
            if [ "$N3" -eq 0 ] && [ "$N4" -eq 1 ] ; then
                echo "Your kernel is 3.10.0-1.x"
                CENTOS="GosLinux64"
            else
            echo "Your kernel is 3.10.x"
            CENTOS=70
            fi
        else
            echo "Warning! Your kernel in not 2.6.x"
        fi
    return 0
}

check_for_suse()
{
   if which lsb_release > /dev/null; then
       lsb_release -d | egrep -q 'openSUSE' || return
   fi

       echo
       echo "Found openSUSE distribution."

       kernel_release4
       N1=`echo $KERNEL4 | cut -d"." -f 1`
       N2=`echo $KERNEL4 | cut -d"." -f 2`
       N3=`echo $KERNEL4 | cut -d"." -f 3 | cut -d"-" -f 1`
       N4=`echo $KERNEL4 | cut -d"-" -f 2 | cut -d"." -f 1`

       SUSE=0
       if [ "$N1" -eq 3 ] && [ "$N2" -eq 16 ] ; then
           if [ "$N3" -eq 7 ] ; then
              SUSE="13_2"
          fi
       fi
   return 0
}

detect_etercifs_sources()
{
    # CentOS-RHEL specific part
    if check_for_openvz ; then
        [ -n "$ETERCIFS_SOURCES_LIST" ] || ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs-*
        if [ "$OVZ_KERNEL" ] ; then
            echo "Building from legacy sources with patch for OpenVZ kernels $OVZ_KERNEL"
            KERNEL_STRING="$OVZ_KERNEL"
        fi
    elif check_for_centos ; then
        [ -n "$ETERCIFS_SOURCES_LIST" ] || ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs-*
        if [ "$CENTOS" -eq 70 ] ; then
            echo "Building from legacy sources with patch for kernels 3.10.x from CentOS 7.0."
            KERNEL_STRING='centos70'
        elif [ "$CENTOS" -eq 60 ] ; then
            echo "Building from legacy sources with patch for kernels 2.6.32-x.y from CentOS 6.0."
            KERNEL_STRING='centos60'
        elif [ "$CENTOS" -eq 57 ] ; then
            # The same as CentOS 5.6
            echo "Building from legacy sources with patch for kernels 2.6.18-274.x from CentOS 5.7."
            KERNEL_STRING='centos56'
        elif [ "$CENTOS" -eq 56 ] ; then
            echo "Building from legacy sources with patch for kernels 2.6.18-238.x from CentOS 5.6."
            KERNEL_STRING='centos56'
        elif [ "$CENTOS" -eq 55 ] ; then
            echo "Building from legacy sources with patch for kernels 2.6.18-194.x from CentOS 5.5."
            KERNEL_STRING='centos55'
        elif [ "$CENTOS" -eq 54 ] ; then
            echo "Building from legacy sources with patch for kernels 2.6.18-164.x from CentOS 5.4."
            KERNEL_STRING='centos54'
        elif [ "$CENTOS" -eq 53 ] ; then
            echo "Building from legacy sources with patch for kernels 2.6.18-128.x from CentOS 5.3."
            KERNEL_STRING='centos53'
        elif [ "$CENTOS" -eq 52 ] ; then
            echo "Building from legacy sources with patch for kernels 2.6.18-92.x from CentOS 5.2."
            KERNEL_STRING='centos52'
        else
            echo "Building from legacy sources."
            KERNEL_STRING='legacy'
        fi # end of CentOS-RHEL specific part
    # start opensuse specific part
    elif check_for_suse; then
        [ -n "$ETERCIFS_SOURCES_LIST" ] || ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs-*
        if [ "$SUSE" = "13_2" ] ; then
           echo "Building from legacy sources with patch for kernels 3.16.7-21.x from SUSE 13.2"
           KERNEL_STRING='suse13_2'
        fi # end suse specific part
    else
        FIRSTNUM=`echo $KERNEL | cut -d"." -f 1`
        if [ "$FIRSTNUM" -eq 2 ] ; then
            [ -n "$ETERCIFS_SOURCES_LIST" ] || ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs-2*
            KERNEL_STRING=$KERNEL
            echo "Building for $KERNEL_STRING"
        elif [ "$FIRSTNUM" -eq 3 ] || [ "$FIRSTNUM" -eq 4 ]; then
            [ -n "$ETERCIFS_SOURCES_LIST" ] || ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs-$FIRSTNUM*
            kernel_release2
            KERNEL_STRING=$KERNEL2
            echo "Building for $KERNEL_STRING"
        fi
    fi

    [ -n "`ls $ETERCIFS_SOURCES_LIST`" ] || fatal "Etercifs kernel module sources does not installed (it is possible, etercifs package is obsoleted)!"
    KERNEL_SOURCE_ETERCIFS_LINK=`ls -1 $ETERCIFS_SOURCES_LIST | grep -F $KERNEL_STRING | sort -r | head -n 1`

    if [ -z "$KERNEL_SOURCE_ETERCIFS_LINK" ] ; then
        ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs-[0-9]*
        KERNEL_SOURCE_ETERCIFS_LINK=`ls -1 $ETERCIFS_SOURCES_LIST | sort -r -V | head -n 1`
        LATEST_SOURCES=`echo $KERNEL_SOURCE_ETERCIFS_LINK | cut -d"-" -f 4`
        echo "Warning! Couldn't find module sources for the current kernel $KERNEL2 ($LATEST_SOURCES sources are selected)!"
        echo "Using the latest supported sources - from v$LATEST_SOURCES kernel!"
        ETERCIFS_SOURCES_LIST=$DATADIR/sources/kernel-source-etercifs*
    fi

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

kernel_release2()
{
    # 3.0
    KERNEL2=`echo $KERNELVERSION | sed 's/\([0-9]\+\.[0-9]\+\).*/\1/'`
}

kernel_release()
{
    # 2.6.27
    KERNEL=`echo $KERNELVERSION | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/'`
}

kernel_release4()
{
    # 2.6.18-128 or 2.6.29.1
    KERNEL4=`echo $KERNELVERSION | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+[\.-][0-9]\+\).*/\1/'`
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
        # workaround for missed link on deb-based systems
        if [ ! -d "$KERNSRC" ] ; then
            local KN=/usr/src/linux-headers-$KERNELVERSION
            [ -d "$KN" ] && KERNSRC="$KN"
        fi
    fi
}

check_headers()
{
    if [ ! -f $KERNSRC/include/linux/version.h ] && [ ! -f $KERNSRC/include/generated/uapi/linux/version.h ] ; then
# TODO: use distr_vendor
        cat >&2 <<EOF
Error: no kernel headers found at $KERNSRC
Please install package
    kernel-headers-modules-XXXX for ALT Linux
    kernel-devel for CentOS / Fedora
    linux-headers-XXXX for Debian / Ubuntu
    kernel-source-XXXX for SUSE Linux
    kernel-source-XXXX for Slackware
    dkms-etercifs for Mandriva
where XXXX is your current version from uname -r: $(uname -r)
or use KERNELVERSION variable to set correct version (for /lib/modules/KERNELVERSION/build)
or use KERNSRC variable to set correct kernel headers location
Exiting...
EOF
# FIXME: check detect
        exit 1
    fi
}

set_gcc()
{
    if [ -f $KERNSRC/gcc_version.inc ] ; then
        . $KERNSRC/gcc_version.inc
        echo "Use GCC $GCC_VERSION"
        export GCCNAME=gcc-$GCC_VERSION
        export USEGCC="CC=$GCCNAME"
    else
        export GCCNAME=gcc
    fi

    [ `which make` ] || fatal "GNU make utility have not found. Please, install make package."

    PATHGCC=`which $GCCNAME`
    [ $PATHGCC ] || fatal "GCC compiler have not found. Please, install gcc package."
    echo $PATHGCC
}

dkms_build_module()
{
    detect_etercifs_sources
    STATUS=`dkms status -m $MODULENAME -v $MODULEVERSION`
    [ "$STATUS" ] || dkms add -m $MODULENAME -v $MODULEVERSION
    tar -xjf $KERNEL_SOURCE_ETERCIFS -C $SRC_DIR
    FILENAME=`basename $KERNEL_SOURCE_ETERCIFS`
    DIRNAME=${FILENAME%.tar.bz2}
    mv -f $SRC_DIR/$DIRNAME/* $SRC_DIR
    BUILDDIR=$SRC_DIR
    change_cifsversion
    rm -rf $SRC_DIR/$DIRNAME
    dkms uninstall -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    dkms build -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    dkms install -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
}

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

compile_module()
{
    detect_etercifs_sources
    create_builddir
    check_headers
    set_gcc

    # SMP build
    [ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
    [ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

    echo "Checking the kernel configuration..."
    if [ -r "$KERNSRC" ]; then
        CONF_STRING=`cat $KERNSRC/.config | grep CONFIG_CIFS=`
        CONF_LETTER=`echo $CONF_STRING | cut -b 13-13`
        case "$CONF_LETTER" in
            "m")
                echo "OK"
                ;;
            "y")
                fatal "ERROR: the kernel is configured with CIFS support, but not as a module!"
                ;;
            *)
                fatal "ERROR: the kernel is configured without CIFS support!"
        esac
    else
        echo "WARNING: the .config file in kernel source directory does not exist!"
    fi

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
    depmod -Ae $KERNELVERSION || exit 1
}

check_build_module()
{
    if [ -r "$BUILDDIR/$MODULEFILENAME" ] ; then
        echo "$KERNELVERSION - OK"
        BUILTLIST="$BUILTLIST---DONE"
    else
        echo "can't locate built module $MODULEFILENAME"
        echo "$KERNELVERSION - FAIL"
        BUILTLIST="$BUILTLIST---FAILURE"
    fi
}

