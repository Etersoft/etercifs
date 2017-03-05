#!/bin/sh

test()
{
    while read distro version source ; do
        ts=$(./source.sh $distro $version < source.table)
        if [ "$ts" = "$source" ] ; then
            res="OK"
        else
            [ -n "$ts" ] && res="NOT OK ($ts != $source)" || res="skip"
        fi
        printf "%20s %20s %10s %s\n" $distro $version $source "$res"
    done
}

# test data
cat <<EOF | test
ALTLinux 2.6.32-ovz-el-alt147 centos60
Ubuntu   4.1.2.4              4.1
GosLinux 3.10.0-1              goslinux64
EOF

