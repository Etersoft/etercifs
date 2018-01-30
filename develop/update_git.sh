#!/bin/bash -x

# creates new branch for the major kernel version or update such branch

fatal()
{
    echo "$@" >&2
    exit 1
}

SOURCESDIR=$(realpath ../sources)
ECSOURCE=../../etercifs-source
MERGEOPT="--no-edit"

UPDATE=''
if [ "$1" = "-u" ] ; then
    UPDATE="$1"
    shift
fi

MV="$1"
[ -n "$MV" ] || fatal "Run with version, f.i. ./update_git.sh 4.11 or ./update_git.sh -u 4.11 for update local sources too"

KTAG=v$MV
KBRANCH=linux-$MV.y

ELIST="etersoft-common etersoft-share-flags etersoft-wine"

update_branch()
{
    LASTTAG=$(git describe --tags upstream/$KBRANCH) || fatal
    echo "Just update branch $KTAG-etercifs to latest commit from $KBRANCH with tag $LASTTAG"
    git checkout $KTAG-etercifs || fatal
    #git merge $MERGEOPT upstream/$KBRANCH || fatal
    git merge $MERGEOPT $LASTTAG || fatal
}

update_sources()
{
    [ -n "$UPDATE" ] || return
    local MV="$1"
    local LASTTAG="$2"

    echo "Copying sources from branch $MV-etercifs to local dir ..."

    local TEXT="update $MV up to $LASTTAG"
    [ -d "$SOURCESDIR/$MV" ] || TEXT="add $MV branch ($LASTTAG)"

    rm -r "$SOURCESDIR/$MV" || fatal
    cp -a fs/cifs "$SOURCESDIR/$MV" || fatal
    cd $SOURCESDIR || fatal
    git commit $MV -m "$TEXT" || fatal
}


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
    update_branch
    update_sources $MV $LASTTAG
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

update_branch
update_sources $MV $LASTTAG
