# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit eutils flag-o-matic multilib

DESCRIPTION="Advanced Common Internet File System for Linux with Etersoft extension"
HOMEPAGE="http://etersoft.ru/wine"
CIFSVER=1.48a
WINENUMVERSION=current
SRC_URI="ftp://updates.etersoft.ru/pub/Etersoft/WINE@Etersoft-$WINENUMVERSION/sources/tarball/${P}.tar.bz2
ftp://updates.etersoft.ru/pub/Etersoft/WINE@Etersoft-$WINENUMVERSION/sources/tarball/cifs-$CIFSVER.tar.bz2"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""
RESTRICT="test" #72375

RDEPEND=">=sys-kernel/linux-headers-2.6"

# this will not build as 64bit code
#export ABI=x86

src_unpack() {
	unpack ${A}
	cd "${WORKDIR}/${P}" || die
	mv ../cifs-bld-tmp ./ || die
	patch -s -p1 -d cifs-bld-tmp/fs/cifs <linux-cifs-shared.patch || die
}

config_cache() {
	local h ans="no"
	use $1 && ans="yes"
	shift
	for h in "$@" ; do
		[[ ${h} == *.h ]] \
			&& h=header_${h} \
			|| h=lib_${h}
		export ac_cv_${h//[:\/.]/_}=${ans}
	done
}

src_compile() {
	export LDCONFIG=/bin/true
	strip-flags
	true
}

src_install() {
	MAN_DIR=${D}/usr/man/ INIT_DIR=${D}/etc/init.d/ SBIN_DIR=${D}/usr/sbin/ INSTALL_MOD_PATH=${D}/lib/modules/ ./build.sh || die
	true
}

pkg_postinst() {
	einfo "Use /etc/init.d/linux-cifs build for build kernel module"
}
