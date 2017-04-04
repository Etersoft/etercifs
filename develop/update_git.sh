#!/bin/sh -x

fatal()
{
    echo "$@" >&2
    exit 1
}

MV="$1"
[ -n "$MV" ] || fatal

ELIST="etersoft-common etersoft-share-flags etersoft-wine"

cd ../../cifs-2.6 || fatal

for i in $ELIST ; do
    git checkout $i || fatal
    git merge $MV || fatal
done

# create branch from tag
git checkout -b $MV-etercifs $MV || fatal

for i in $ELIST ; do
    git merge $i || fatal
done
