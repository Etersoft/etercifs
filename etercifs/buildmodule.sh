#!/bin/sh
# 2007-2010, 2017 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# modified: Konstantin Baev <kipruss@etersoft.ru>
# GNU Public License

# Build kernel module in installed system

# in kernel build dir you can have gcc_version.inc file with export GCC_VERSION=x.xx

. ./functions.sh

    detect_host_kernel
    if [ -r $SRC_DIR/dkms.conf ] && which dkms 2>/dev/null >/dev/null ] ; then
        echo
        echo "Building $MODULENAME $MODULEVERSION for $KERNELVERSION Linux kernel with dkms"
        dkms_build_module
    else
        echo
        echo "Building $MODULENAME $MODULEVERSION for $KERNELVERSION Linux kernel (use headers in $KERNSRC)"
        compile_module
        install_module
    fi

