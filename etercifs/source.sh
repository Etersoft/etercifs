#!/bin/sh
# 2017 (c) Etersoft http://etersoft.ru
# Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# TODO: arg: Distro KERNELVERSION
# Parse source.table and print result source version

SYSTEM="$1"
KERNELVERSION="$2"
[ -z "$KERNELVERSION" ] && VERBOSE=1

sort_dn()
{
    # sort -V
    sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4 -g "$@"
}

# <=
verlte() {
    [  "$1" = "`( echo "$1" ; echo "$2" ; ) | sort_dn | head -n1`" ]
}

# <
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

skip=1
while read vers source other; do
    echo "$vers" | grep -q " *#" && continue
    [ -n "$vers" ] || continue
    if echo "$vers" | grep -q "^\[" ; then
        systems=$(echo "$vers" | sed -e "s|\[||g" | sed -e "s|\]||g")
        [ -n "$VERBOSE" ] && echo "Systems: $systems"
        echo "$SYSTEM" | egrep -q "$systems" && skip= || skip=1
        prevvers=
        continue
    fi
    [ -n "$VERBOSE" ] && echo "$vers - $prevvers: $source"

    # vers is regular expression
    if echo "$vers" | grep -q "\*" ; then
        if echo "$KERNELVERSION" | egrep -q "$vers" ; then
            echo "$source"
            exit
        fi
        # do not count regexps
        # prevvers="$vers"
        continue
    fi

    # vers is a kernel version
    if [ -z "$skip" ] && ! verlt "$KERNELVERSION" "$vers" ; then
        if [ -z "$prevvers" ] || verlt "$KERNELVERSION" "$prevvers" ; then
            [ -n "$source" ] && echo "$source" || echo "$vers"
            exit
        fi
    fi

    prevvers="$vers"
done
