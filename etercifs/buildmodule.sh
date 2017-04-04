#!/bin/sh
# 2007-2010, 2017 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# modified: Konstantin Baev <kipruss@etersoft.ru>
# GNU Public License

# Build kernel module in installed system

# in kernel build dir you can have gcc_version.inc file with export GCC_VERSION=x.xx

. ./functions.sh

detect_kernel_source()
{
    KERNELMANUAL="$KERNSRC$KERNELVERSION"
    [ -n "$KERNELVERSION" ] || KERNELVERSION=`uname -r`

    if [ -z "$KERNSRC" ]; then
        KERNSRC=/lib/modules/$KERNELVERSION/build
        if [ ! -d "$KERNSRC" ] ; then
            # workaround for missed link on deb-based systems
            local KN=/usr/src/linux-headers-$KERNELVERSION
            [ -d "$KN" ] && KERNSRC="$KN"
            # workaround for Fedora 25 and later
            KN=/usr/src/kernels/$KERNELVERSION
            [ -d "$KN" ] && KERNSRC="$KN"
        fi
    else
        # [ -n "$KV" ] || fatal "Set both KERNSRC and KERNVERSION"
        # override KERNELVERSION if have KERNSRC
        local BD=$(dirname "$KERNSRC")
        if [ "$BD" = "build" ] ; then
            KERNELVERSION=$(basename $(dirname "$KERNSRC"))
        else
            KERNELVERSION=$(basename "$KERNSRC")
        fi
    fi
}

    detect_kernel_source

    if [ -r $SRC_DIR/dkms.conf ] && which dkms 2>/dev/null >/dev/null ; then
        echo
        echo "Building $MODULENAME $MODULEVERSION for $KERNELVERSION Linux kernel with dkms"
        dkms_build_module
    else
        echo
        echo "Building $MODULENAME $MODULEVERSION for $KERNELVERSION Linux kernel (use headers in $KERNSRC)"
        compile_module || fatal
        install_module
    fi

