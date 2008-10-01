#!/bin/sh
# 2007 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# Build kernel modules for all kernel and all platforms

fatal()
{
    echo $@
    exit 1
}

DISTR_VENDOR=/usr/bin/distr_vendor

test -x $DISTR_VENDOR || fatal "Can't find distr_vendor"

get_sd()
{
    BASE_KERNEL_SOURCES_DIR=
    BASE_KERNEL_SOURCES_DIR=`grep -i $1 kernel_src.list | head -n1 | cut -d" " -f 2 2>/dev/null`
    ETERCIFS_SOURCES_LIST=
    ETERCIFS_SOURCES_LIST=`grep -i $1 etercifs_src.list | head -n1 | cut -d" " -f 2 2>/dev/null`
}

get_src_dir()
{
    get_sd `$DISTR_VENDOR -e`
    [ -z "$BASE_KERNEL_SOURCES_DIR" ] && get_sd `$DISTR_VENDOR -d`
    [ -z "$BASE_KERNEL_SOURCES_DIR" ] && { echo "Unknown `$DISTR_VENDOR -d`, use Generic" ; get_sd Generic ; }
    [ -z "$BASE_KERNEL_SOURCES_DIR" ] && return 1
    return 0
}

exit_handler()
{
    local rc=$?
    trap - EXIT
    [ -z "$tmpdir" ] || rm -rf -- "$tmpdir"
    exit $rc
}

#/lib/modules/$(shell uname -r)/build

#fatal "Errror in func"

