# Etersoft (c) 2007
# Multiplatform spec for autobuild system

# in kernel build dir you can have gcc_version.inc file with export GCC_VERSION=x.xx

# For build install,
# 	kernel-headers-modules-XXXX for ALT Linux
# 	kernel-devel-XXXX for FCx / ASP Linux
# 	kernel-source-stripped-XXXX for Mandriva 2007
# 	linux-headers for Debian / Ubuntu
# 	kernel-source-XXXX for SuSe
# 	kernel-source-XXXX for Slackware / MOPSLinux

Name: linux-cifs
Version: 1.48a
%define relnum 3

Summary: Advanced Common Internet File System for Linux with Etersoft extension

Packager: Vitaly Lipatov <lav@altlinux.ru>

License: GPL 2
Group: System/Kernel and hardware
Url: http://linux-cifs.samba.org/

Source: ftp://updates.etersoft.ru/pub/Etersoft/WINE@Etersoft/sources/tarball/%name-%version.tar.bz2
Source1: http://pserver.samba.org/samba/ftp/cifs-cvs/cifs-%version.tar.bz2

# Spec part for ALT Linux
%if %_vendor == "alt"
Release: alt%relnum
BuildRequires: rpm-build-compat >= 0.7
BuildRequires: kernel-build-tools
BuildRequires: kernel-headers-modules-std-smp kernel-headers-modules-wks-smp kernel-headers-modules-ovz-smp
%ifarch x86_64
# Don't know if ifnarch exist
BuildRequires: kernel-headers-modules-std-smp
%else
BuildRequires: kernel-headers-modules-std-pae
%endif
%else
Release: eter%relnum%_vendor
BuildRequires: rpm-build-altlinux-compat >= 0.7
%endif

# FIXME: ifndef broken in Ubuntu
#ifndef buildroot
%if %{undefined buildroot}
BuildRoot: %{_tmppath}/%{name}-%{version}-buildroot
%endif

%if %_vendor == "suse"
# due kernel dependencies
AutoReq: no
%endif

%define module_dir /lib/modules/%name

ExclusiveOS: Linux
#ExclusiveArch: i586

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

%prep
%setup -q
tar xfj %SOURCE1
patch -s -p1 -d cifs-bld-tmp/fs/cifs <%name-shared.patch

%install
#export KBUILD_VERBOSE=1
MAN_DIR=%buildroot%_mandir/ INIT_DIR=%buildroot%_initdir/ SBIN_DIR=%buildroot%_sbindir/ INSTALL_MOD_PATH=%buildroot%module_dir ./build.sh

# Debian, Suse, Slackware do not have command service
# start service if first time install
%post
%post_service %name
[ "$1" = "1" ] && %_initdir/%name start || :

%preun
%preun_service %name

%files
%defattr(-,root,root)
%_initdir/%name
%_initdir/%name.outformat
%module_dir/
/usr/src/%name/

%changelog
* Thu Jun 14 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt3
- WINE@Etersoft 1.0.7 beta
- fix inode revalidate for read requests
- fix build module scripts

* Tue Jun 12 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt2
- WINE@Etersoft 1.0.7 alpha

* Fri Jun 08 2007 Vitaly Lipatov <lav@altlinux.ru> 1.48a-alt1
- initial build for WINE@Etersoft project
