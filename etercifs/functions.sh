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


kernel_release2()
{
    # 3.0
    KERNEL=`echo "$KERNELVERSION" | sed 's/\([0-9]\+\.[0-9]\+\).*/\1/'`
}

kernel_release3()
{
    # 2.6.27
    KERNEL=`echo "$KERNELVERSION" | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/'`
}

kernel_release4()
{
    # 2.6.18-128 or 2.6.29.1
    KERNEL=`echo "$KERNELVERSION" | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+[\.-][0-9]\+\).*/\1/'`
}

split_kernel_version()
{
    N1=$(echo "$KERNEL" | cut -d"." -f 1)
    N2=$(echo "$KERNEL" | cut -d"." -f 2)
    N3=$(echo "$KERNEL" | cut -d"." -f 3 | cut -d"-" -f 1)
    N4=$(echo "$KERNEL" | cut -d"-" -f 2 | cut -d"." -f 1)
}

list_source_versions()
{
    tar --list --no-recursion -f $ETERCIFS_SOURCES_TARBALL --exclude '*/*' | sed -e "s|/||g"
}

# arg: version target
extract_source()
{
    mkdir -p "$2" || return
    tar -xJf $ETERCIFS_SOURCES_TARBALL -C "$2" --strip 1 "$1"
}

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

check_for_centos()
{
    # TODO: epm
    if which lsb_release > /dev/null; then
        lsb_release -d | egrep -q 'GosLinux|CentOS|Red Hat|Scientific Linux|NauLinux|LinuxWizard Server|RERemix' || return
    fi

        echo
        echo "Found RHEL-like distribution."

        kernel_release4
        split_kernel_version

        if [ "$N1.$N2" = "2.6" ] ; then
            if [ "$N3" = "18" ] ; then
                if [ "$N4" = "274" ] ; then
                    echo "Building from legacy sources with patch for kernels 2.6.18-274.x from CentOS 5.7."
                    KERNEL_STRING='centos56'
                elif [ "$N4" -gt 274 ] ; then
                    echo "Building from legacy sources with patch for kernels 2.6.18-238.x from CentOS 5.6."
                    KERNEL_STRING='centos56'
                elif [ "$N4" -eq 238 ] ; then
                    echo "Your kernel is 2.6.18-238.x"
                    KERNEL_STRING='centos56'
                elif [ "$N4" -gt 238 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-238.x"
                    KERNEL_STRING='centos56'
                elif [ "$N4" -eq 194 ] ; then
                    echo "Your kernel is 2.6.18-194.x"
                    echo "Building from legacy sources with patch for kernels 2.6.18-194.x from CentOS 5.5."
                    KERNEL_STRING='centos55'
                elif [ "$N4" -gt 194 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-194.x and older than 2.6.18.238.x"
                    echo "Building from legacy sources with patch for kernels 2.6.18-194.x from CentOS 5.5."
                    KERNEL_STRING='centos55'
                elif [ "$N4" -eq 164 ] ; then
                    echo "Building from legacy sources with patch for kernels 2.6.18-164.x from CentOS 5.4."
                    KERNEL_STRING='centos54'
                elif [ "$N4" -gt 164 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-164.x and older than 2.6.18.194.x"
                    echo "Building from legacy sources with patch for kernels 2.6.18-164.x from CentOS 5.4."
                    KERNEL_STRING='centos54'
                elif [ "$N4" -eq 128 ] ; then
                    echo "Building from legacy sources with patch for kernels 2.6.18-128.x from CentOS 5.3."
                    KERNEL_STRING='centos53'
                elif [ "$N4" -gt 128 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-128.x and older than 2.6.18-164.x"
                    echo "Building from legacy sources with patch for kernels 2.6.18-128.x from CentOS 5.3."
                    KERNEL_STRING='centos53'
                elif [ "$N4" -eq 92 ] ; then
                    echo "Building from legacy sources with patch for kernels 2.6.18-92.x from CentOS 5.2."
                    KERNEL_STRING='centos52'
                elif [ "$N4" -gt 92 ] ; then
                    echo "Warning! Your kernel is newer than 2.6.18-92.x and older than 2.6.18-128.x"
                    echo "Building from legacy sources with patch for kernels 2.6.18-92.x from CentOS 5.2."
                    KERNEL_STRING='centos52'
                else
                    echo "Warning! Your kernel is older than 2.6.18-92.x"
                    echo "Building from legacy sources."
                    KERNEL_STRING='legacy'
                fi
            elif [ "$N3" -gt 18 ] && [ "$N3" -lt 23 ] ; then
                    echo "Building from legacy sources with patch for kernels 2.6.18-92.x from CentOS 5.2."
                    KERNEL_STRING='centos52'
            elif [ "$N3" = "32" ] ; then
                echo "Building from legacy sources with patch for kernels 2.6.32-x.y from CentOS 6.0."
                KERNEL_STRING='centos60'
            else
                echo "Warning! Your RHEL kernel is older than 2.6.18 or newer than 2.6.23"
                echo "Building from legacy sources."
                KERNEL_STRING='legacy'
            fi
        elif [ "$N1.$N2" = "3.10" ] ; then
            if [ "$N3-$N4" = "0-1" ] ; then
                # FIXME
                CENTOS="GosLinux64"
            else
                echo "Building from legacy sources with patch for kernels 3.10.x from CentOS 7.0."
                KERNEL_STRING='centos70'
            fi
        else
            echo "Skipping RHEL specific kernel $KERNEL"
            return 1
        fi
    return 0
}

check_for_suse()
{
   # TODO epm
   if which lsb_release > /dev/null; then
       lsb_release -d | egrep -q 'openSUSE' || return
   fi

       echo
       echo "Found openSUSE distribution."

       kernel_release4
       split_kernel_version

       if [ "$N1.$N2.$N3" = "3.16.7" ] ; then
           echo "Building from legacy sources with patch for kernels 3.16.7-21.x from SUSE 13.2"
           KERNEL_STRING='suse13_2'
       else
           return 1
       fi
   return 0
}

detect_etercifs_sources()
{
    KERNEL_STRING=

    if check_for_openvz ; then
        echo "Building from legacy sources with patch for OpenVZ kernel $KERNEL_STRING"
    elif check_for_centos ; then
        true
    elif check_for_suse; then
        true
    else
        kernel_release3
        split_kernel_version
        if [ "$N1" -eq 2 ] ; then
            # 2.x.x regular kernel
            KERNEL_STRING=$KERNEL
            echo "Building for $KERNEL_STRING kernel version"
        else
            # some normal and modern kernel
            kernel_release2
            KERNEL_STRING=$KERNEL
            echo "Building for $KERNEL_STRING kernel version"
        fi
    fi

    # try get concrete version
    KERNEL_SOURCE_ETERCIFS=$(list_source_versions | grep -F "$KERNEL_STRING" | sort -r | head -n 1)

    # try get like version
    if [ -z "$KERNEL_SOURCE_ETERCIFS" ] ; then
        KERNEL_SOURCE_ETERCIFS=$(list_source_versions | sort -r -V | head -n 1)
        if [ -n "$KERNEL_SOURCE_ETERCIFS" ] ; then
            LATEST_SOURCES=$(echo $KERNEL_SOURCE_ETERCIFS | cut -d"-" -f 4)
            echo "Warning! Couldn't find module sources for the kernel $KERNEL!"
            echo "Using the latest supported sources - from v$LATEST_SOURCES kernel!"
        else
            echo "Can't locate any appropiate kernel sources for the kernel $KERNEL"
        fi
    fi

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
        BUILDDIR=$tmpdir/$KERNEL_SOURCE_ETERCIFS
    fi
    extract_source $KERNEL_SOURCE_ETERCIFS $BUILDDIR
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
    kernel_release3
}

detect_host_kernel()
{
    local KV="$KERNELVERSION"
    [ -n "$KERNELVERSION" ] || KERNELVERSION=`uname -r`
    kernel_release3

    if [ -z "$KERNSRC" ]; then
        KERNSRC=/lib/modules/$KERNELVERSION/build
        # workaround for missed link on deb-based systems
        if [ ! -d "$KERNSRC" ] ; then
            local KN=/usr/src/linux-headers-$KERNELVERSION
            [ -d "$KN" ] && KERNSRC="$KN"
        fi
    else
        # [ -n "$KV" ] || fatal "Set both KERNSRC and KERNVERSION"
        KERNELVERSION=$(basename $(dirname "$KERNSRC"))
    fi
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
        exit 1
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
    detect_etercifs_sources
    STATUS=`dkms status -m $MODULENAME -v $MODULEVERSION`
    [ "$STATUS" ] || a= dkms add -m $MODULENAME -v $MODULEVERSION
    BUILDDIR=$SRC_DIR
    create_builddir || fatal
    change_cifsversion
    a= dkms uninstall -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    a= dkms build -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
    a= dkms install -m $MODULENAME -v $MODULEVERSION --rpm_safe_upgrade
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

compile_module()
{
    detect_etercifs_sources
    check_headers || return
    create_builddir || return
    set_gcc

    # SMP build
    [ -z "$RPM_BUILD_NCPUS" ] && RPM_BUILD_NCPUS=`/usr/bin/getconf _NPROCESSORS_ONLN`
    [ "$RPM_BUILD_NCPUS" -gt 1 ] && MAKESMP="-j$RPM_BUILD_NCPUS" || MAKESMP=""

    echo "Checking the kernel configuration..."
    if [ -r "$KERNSRC/.config" ]; then
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

