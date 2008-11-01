#!/bin/sh
# 2007-2008 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# modified: Konstantin Baev <kipruss@etersoft.ru>

# Build kernel module in installed system

. ./functions.sh

if [ $TESTBUILD -ne 1 ] ; then
    detect_host_kernel
    echo
    echo "Building for $KERNELVERSION Linux kernel (headers in $KERNSRC)"
    compile_module
    install_module
else
    echo
    echo "====================================================================="
    echo "Check build etercifs module for all founded kernels"
    BUILTLIST=
    [ -n "$KERNEL_SRC_LIST" ] || KERNEL_SRC_LIST=`readlink /lib/modules/*/build`
    for KERNSRC in $KERNEL_SRC_LIST ; do
        [ -L $KERNSRC ] && [ `basename $KERNSRC` != "build" ] && continue
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
    done
    echo "====================================================================="
    echo "CIFS Linux kernel module built for follow kernels (marked as ---DONE):"
    echo "---------------------------------------------------------------------"
    for i in $BUILTLIST ; do echo "    $i" ; done
    echo "====================================================================="
fi

exit 0

