%define modname	linux-cifs

Name: dkms-linux-cifs
Version: 1.50c
Release: alt1
Summary: DKMS-ready CIFS Linux kernel module with Etersoft extensions
License: GPL
Packager: Vitaly Lipatov <lav@altlinux.ru>

#Source: ftp://updates.etersoft.ru/pub/Etersoft/WINE@Etersoft/sources/tarball/%name-%version.tar.bz2

Group: Development/Kernel
Requires(preun): dkms
Requires(post): dkms

Requires: linux-cifs

Buildarch: noarch

%description
The CIFS VFS is a virtual file system for Linux to allow access to
servers and storage appliances compliant with the SNIA CIFS Specification
version 1.0 or later.

This package contains DKMS-ready CIFS Linux kernel module with Etersoft extensions.

%prep
%setup -c -T -n %name-%version

%install
mkdir -p %buildroot%_usrsrc/%modname-%version/
cat > %buildroot%_usrsrc/%modname-%version/dkms.conf <<EOF
# DKMS file for Linux CIFS with Etersoft's extensions

PACKAGE_NAME="%modname"
PACKAGE_VERSION="%version"

BUILT_MODULE_NAME[0]="etercifs"
DEST_MODULE_LOCATION[0]="/kernel/fs/cifs/"
REMAKE_INITRD="no"
AUTOINSTALL="YES"
EOF

%post
if [ "$1" == 1 ]
then
  dkms add -m %modname -v %version --rpm_safe_upgrade
fi
dkms build -m %modname -v %version --rpm_safe_upgrade
dkms install -m %modname -v %version --rpm_safe_upgrade

%preun
if [ "$1" == 0 ]
then
  dkms remove -m %modname -v %version --rpm_safe_upgrade --all
fi

%files
%_usrsrc/%modname-%version/dkms.conf

%changelog
* Sat Jan 26 2008 Vitaly Lipatov <lav@altlinux.ru> 1.50c-alt1
- initial build for Korinf project

