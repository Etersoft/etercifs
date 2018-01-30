#!/bin/bash -x

# creates new branch for the major kernel version or update such branch

fatal()
{
    echo "$@" >&2
    exit 1
}

ECSOURCE=../../etercifs-source
MERGEOPT="--no-edit"

MV="$1"
[ -n "$MV" ] || fatal "Run with version, f.i. ./update_git.sh 4.11"

KTAG=v$MV
KBRANCH=linux-$MV.y

ELIST="etersoft-common etersoft-share-flags etersoft-wine"

if [ ! -d $ECSOURCE ] ; then
    cd $(dirname $ECSOURCE) || fatal
    git clone https://gitlab.eterfund.ru/etersoft/etercifs-source.git || fatal
    cd etercifs-source || fatal
    git remote add upstream https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
else
    cd $ECSOURCE || fatal
fi

git fetch upstream

git tag | grep "$KTAG" || fatal "There is no $KTAG tag in the git repo."

if git branch | grep -q $KTAG-etercifs ; then
    LASTTAG=$(git describe --tags upstream/$KBRANCH) || fatal
    echo "Just update branch $KTAG-etercifs to latest commit from $KBRANCH with tag $LASTTAG"
    git checkout $KTAG-etercifs || fatal
    #git merge $MERGEOPT upstream/$KBRANCH || fatal
    git merge $MERGEOPT $LASTTAG || fatal
    exit
fi

echo
echo "Update branches..."
for i in $ELIST ; do
    git checkout $i || fatal
    git merge $MERGEOPT $KTAG || fatal
done

echo
echo "Create branch from the tag and merge all to it..."
git checkout -b $MV-etercifs $KTAG || fatal

for i in $ELIST ; do
    git merge $MERGEOPT $i || fatal
done

echo "You are in branch $MV-etercifs, copy fs/cifs to "
