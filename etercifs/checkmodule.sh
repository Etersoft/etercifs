#!/bin/sh
# 2007-2010, 2017 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# modified: Konstantin Baev <kipruss@etersoft.ru>
# GNU Public License

. ./functions.sh

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
        fi
    done
    echo "====================================================================="
    echo "CIFS Linux kernel module $MODULENAME $MODULEVERSION built for follow kernels (marked as ---DONE or ---FAILURE):"
    echo "---------------------------------------------------------------------"
    for i in $BUILTLIST ; do echo "    $i" ; done
    echo "====================================================================="

exit 0

