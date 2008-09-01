#!/bin/sh
# 2006, 2007, 2008 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

echo "All kernel build script. (c) 2007, 2008 Etersoft. $Id: build.sh,v 1.26 2008/01/27 16:54:11 lav Exp $"
PACKNAME=linux-cifs
MODULENAME=etercifs
SRC_DIR=/tmp

mkdir -p $INIT_DIR

sed -e "s|@SRC_DIR@|$SRC_DIR|g" < $PACKNAME.init > $PACKNAME.init.repl
install -m755 -D $PACKNAME.init.repl $INIT_DIR/$PACKNAME
install -m755 $PACKNAME.outformat $INIT_DIR/


exit 0
