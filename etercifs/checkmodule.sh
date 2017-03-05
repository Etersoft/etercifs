#!/bin/sh
# 2007-2010, 2017 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# modified: Konstantin Baev <kipruss@etersoft.ru>
# GNU Public License

. ./functions.sh

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



    echo
    echo "====================================================================="
    echo "Check build etercifs module for all found kernels"
    BUILTLIST=
    for KERNSRC in $(list_kernel_headers) ; do
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
    echo "CIFS Linux kernel module $MODULENAME $MODULEVERSION built for follow kernels (marked as ---DONE or ---FAILURE):"
    echo "---------------------------------------------------------------------"
    for i in $BUILTLIST ; do echo "    $i" ; done
    echo "====================================================================="

exit 0

