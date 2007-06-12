#!/bin/sh
# 2007 (c) Etersoft http://etersoft.ru
# Author: Vitaly Lipatov <lav@etersoft.ru>
# GNU Public License

# тут нужно получить список версий ядер...
for KERN in `find /lib/modules -maxdepth 1 -type d` ; do
	[ -L "$KERN" ] && continue
	[ -d "$KERN/kernel/extra/" ] || continue

	KERNELVERSION=`basename $KERN`
	[ -f /boot/System.map-$KERNELVERSION ] && /sbin/depmod -a -F /boot/System.map-$KERNELVERSION $KERNELVERSION
done

exit 0
