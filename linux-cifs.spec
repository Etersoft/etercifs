# Etersoft (c) 2007, 2008
# Multiplatform spec for autobuild system

# in kernel build dir you can have gcc_version.inc file with export GCC_VERSION=x.xx

# For build install,
# 	kernel-headers-modules-XXXX for ALT Linux
# 	kernel-devel-XXXX for FCx / ASP Linux
# 	kernel-source-stripped-XXXX for Mandriva 2007
# 	linux-headers for Debian / Ubuntu
# 	kernel-source-XXXX for SuSe
# 	kernel-source-XXXX for Slackware / MOPSLinux

%define src_package_name kernel-source-etercifs-legacy
%define src_package_version 1.50c

Name: linux-cifs
Version: 1.0
Release: alt1
Serial: 1

Summary: Advanced Common Internet File System for Linux with Etersoft extension

Packager: Konstantin Baev <kipruss@altlinux.org>

License: GPLv2
Group: System/Kernel and hardware
Url: http://git.etersoft.ru/

BuildArch: noarch

#Source: ftp://updates.etersoft.ru/pub/Etersoft/WINE@Etersoft/sources/tarball/%name-%version.tar.bz2
#Source1: http://pserver.samba.org/samba/ftp/cifs-cvs/cifs-%version.tar.bz2

Source: %name-%version.tar.bz2
Source1: %src_package_name-%src_package_version.tar.bz2

BuildRequires: rpm-build-compat >= 0.97

# Spec part for ALT Linux
%if %_vendor == "alt"
BuildRequires: kernel-build-tools
BuildRequires: kernel-headers-modules-std-def
#BuildRequires: kernel-headers-modules-std-smp kernel-headers-modules-ovz-smp kernel-headers-modules-std-def
# do not work?
%ifarch x86_64
# Don't know if ifnarch exist
BuildRequires: kernel-headers-modules-std-smp
%else
#BuildRequires: kernel-headers-modules-std-pae
%endif
%endif

%if %_vendor == "suse"
# due kernel dependencies
AutoReq: no
%endif

Requires: kernel-source-etercifs-legacy
Requires: kernel-source-etercifs-2.6.23
Requires: kernel-source-etercifs-2.6.24
Requires: kernel-source-etercifs-2.6.25

%define module_dir /lib/modules/%name

ExclusiveOS: Linux

%description
The CIFS VFS is a virtual file system for Linux to allow access to
servers and storage appliances compliant with the SNIA CIFS Specification
version 1.0 or later.
Popular servers such as Samba, Windows 2000, Windows XP and many others
support CIFS by default.
The CIFS VFS provides some support for older servers based on the more
primitive SMB (Server Message Block) protocol (you also can use the Linux
file system smbfs as an alternative for accessing these).
CIFS VFS is designed to take advantage of advanced network file system
features such as locking, Unicode (advanced internationalization),
hardlinks, dfs (hierarchical, replicated name space), distributed caching
and uses native TCP names (rather than RFC1001, Netbios names).

Unlike some other network file systems all key network function including
authentication is provided in kernel (and changes to mount and/or a mount
helper file are not required in order to enable the CIFS VFS). With the
addition of upcoming improvements to the mount helper (mount.cifs) the
CIFS VFS will be able to take advantage of the new CIFS URL specification
though.

This package has Etersoft's patches for WINE@Etersoft sharing access support.

#cifs-bld-tmp/fs/cifs
%define intdir new-cifs-backport

%package -n %src_package_name
Version: %src_package_version
Summary: Advanced Common Internet File System for Linux with Etersoft extension - module sources
Group: Development/Kernel
BuildArch: noarch

%description -n %src_package_name
The CIFS VFS is a virtual file system for Linux to allow access to
servers and storage appliances compliant with the SNIA CIFS Specification
version 1.0 or later.
Popular servers such as Samba, Windows 2000, Windows XP and many others
support CIFS by default.
The CIFS VFS provides some support for older servers based on the more
primitive SMB (Server Message Block) protocol (you also can use the Linux
file system smbfs as an alternative for accessing these).
CIFS VFS is designed to take advantage of advanced network file system
features such as locking, Unicode (advanced internationalization),
hardlinks, dfs (hierarchical, replicated name space), distributed caching
and uses native TCP names (rather than RFC1001, Netbios names).

Unlike some other network file systems all key network function including
authentication is provided in kernel (and changes to mount and/or a mount
helper file are not required in order to enable the CIFS VFS). With the
addition of upcoming improvements to the mount helper (mount.cifs) the
CIFS VFS will be able to take advantage of the new CIFS URL specification
though.

This package has Etersoft's patches for WINE@Etersoft sharing access support.

%prep
%setup -q

%install
mkdir -p %kernel_srcdir
cp %SOURCE1 %kernel_srcdir/%src_package_name-%src_package_version.tar.bz2
for N in `seq 18 22`
do
  ln -s %kernel_src/%src_package_name-%src_package_version.tar.bz2 %kernel_srcdir/kernel-source-etercifs-2.6.$N-%src_package_version.tar.bz2
done

mkdir -p %buildroot%_datadir/%name
install -m644 buildmodule.sh functions.sh kernel_src.list %buildroot%_datadir/%name

mkdir -p %buildroot%_initdir
sed -e "s|@DATADIR@|%_datadir/%name|g" < %name.init > %name.init.repl
install -m755 %name.init.repl %buildroot%_initdir/%name
install -m755 %name.outformat %buildroot%_initdir/%name.outformat

%files
%_datadir/%name/*
%_initdir/%name
%_initdir/%name.outformat

%files -n %src_package_name
%attr(0644,root,root) %kernel_src/%src_package_name-%src_package_version.tar.bz2
%kernel_src/kernel-source-etercifs-2.6.??-%src_package_version.tar.bz2

%changelog
* Wed Sep 03 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt1
- sources changed - now it's with Etersoft patches
- source directory renamed to cifs
- sources will be packaged in separate kernel-source package,
  named kernel-source-etercifs-legacy-1.50c
- no more compiled module etercifs.ko in rpm, just install scripts and src
- one script builds etercifs module for several kerneld from other sources

* Thu Jan 31 2008 Vitaly Lipatov <lav@altlinux.ru> 1.50c-alt4
- fix build on Fedora 8 (2.6.18-53)

* Sun Jan 27 2008 Vitaly Lipatov <lav@altlinux.ru> 1.50c-alt3
- move modules placement
- move src files to name-version for dkms compatibility
- change module name to etercifs.ko

* Fri Dec 28 2007 Vitaly Lipatov <lav@altlinux.ru> 1.50c-alt2
- add fix for SLED10 kernel 2.6.16.46
- fix warnings, add missed access setting in reopen file func

* Tue Nov 06 2007 Vitaly Lipatov <lav@altlinux.ru> 1.50c-alt1
- update version
- fix spec according to Korinf build system

* Fri Oct 12 2007 Vitaly Lipatov <lav@altlinux.ru> 1.50-alt1
- update version

* Fri Sep 14 2007 Sergey Lebedev <barabashka@altlinux.ru> 1.50-alt0
- new version cifs 1.50

* Fri Jul 27 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt7
- fix build on 2.6.22 kernels
- fix scripts for Debian/Ubuntu

* Tue Jun 26 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt6
- WINE@Etersoft 1.0.7 bugfix release
- some start script fixes, install manually build first
- fix build for kernels in symlinked build dir
- fix build on ASP Linux 2.6.9-55 kernels

* Tue Jun 19 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt5
- WINE@Etersoft 1.0.7 release
- fix build on ALT ovz-smp
- fix build with 2.6.9 and older kernel
- fix build on ALT Linux 2.4
- fix caching after oplock break (eterbug #477)
- fix build with 2.6.18 on CentOS/5 and Fedora

* Sun Jun 17 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt4
- WINE@Etersoft 1.0.7 rc1
- script fixes

* Thu Jun 14 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt3
- WINE@Etersoft 1.0.7 beta
- fix inode revalidate for read requests
- fix build module scripts

* Tue Jun 12 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt2
- WINE@Etersoft 1.0.7 alpha

* Fri Jun 08 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt1
- initial build for WINE@Etersoft project
