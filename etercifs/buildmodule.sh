#!/bin/sh
# 2007-2010 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# modified: Konstantin Baev <kipruss@etersoft.ru>
# GNU Public License

# Build kernel module in installed system

# in kernel build dir you can have gcc_version.inc file with export GCC_VERSION=x.xx

. ./functions.sh

if [ $TESTBUILD -ne 1 ] ; then
    if [ $DKMSBUILD -eq 1 ] ; then
        detect_host_kernel
        echo
        echo "Building $MODULENAME $MODULEVERSION for $KERNELVERSION Linux kernel with dkms"
        dkms_build_module
    else
        detect_host_kernel
        echo
        echo "Building $MODULENAME $MODULEVERSION for $KERNELVERSION Linux kernel (headers in $KERNSRC)"
        compile_module
        install_module
    fi
else
    echo
    echo "====================================================================="
    echo "Check build etercifs module for all found kernels"
    BUILTLIST=
    for LM in `ls /lib/modules` ; do
        KERNSRC=`readlink /lib/modules/$LM/build`
        if [ $KERNSRC ] ; then
            [ -L $KERNSRC ] && continue
            [ -f $KERNSRC/.config ] || continue
            echo "---------------------------------------------------------------------"
            detect_kernel
            if [ -z "$KERNELVERSION" ] ; then
                echo "Can't detect kernel version in $KERNSRC"
            else
                echo "Build for $KERNSRC (detected as $KERNELVERSION)"
                BUILTLIST="$BUILTLIST $KERNELVERSION"
                compile_module
                check_build_module
            fi
        fi
    done
    echo "====================================================================="
    echo "CIFS Linux kernel module $MODULENAME $MODULEVERSION built for follow kernels (marked as ---DONE or ---FAILURE):"
    echo "---------------------------------------------------------------------"
    for i in $BUILTLIST ; do echo "    $i" ; done
    echo "====================================================================="
fi

exit 0

