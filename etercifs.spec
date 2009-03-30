# Etersoft (c) 2007, 2008
# Multiplatform spec for autobuild system

# in kernel build dir you can have gcc_version.inc file with export GCC_VERSION=x.xx

# For build install,
# 	kernel-headers-modules-XXXX for ALT Linux
# 	kernel-devel-XXXX for FCx / ASP Linux
# 	dkms-etercifs for Mandriva 2009
# 	linux-headers for Debian / Ubuntu
# 	kernel-source-XXXX for SuSe
# 	kernel-source-XXXX for Slackware / MOPSLinux

%define src_package_name kernel-source-etercifs
%define src_legacy_version 1.50c
%define src_2_6_16_version 1.50
%define src_2_6_23_version 1.50
%define src_2_6_24_version 1.52
%define src_2_6_25_version 1.52
%define src_2_6_26_version 1.53
%define src_2_6_27_version 1.54
%define src_2_6_28_version 1.55
%define src_2_6_29_version 1.57

Name: etercifs
Version: 4.3.0
Release: alt1

Summary: Advanced Common Internet File System for Linux with Etersoft extension

Packager: Konstantin Baev <kipruss@altlinux.org>

License: GPLv2
Group: System/Kernel and hardware
Url: ftp://updates.etersoft.ru/pub/Etersoft/CIFS@Etersoft/

BuildArch: noarch

Source: %name-%version.tar.bz2
Source1: %src_package_name-legacy-%src_legacy_version.tar.bz2
Source16: %src_package_name-2.6.16-%src_2_6_16_version.tar.bz2
Source23: %src_package_name-2.6.23-%src_2_6_23_version.tar.bz2
Source24: %src_package_name-2.6.24-%src_2_6_24_version.tar.bz2
Source25: %src_package_name-2.6.25-%src_2_6_25_version.tar.bz2
Source26: %src_package_name-2.6.26-%src_2_6_26_version.tar.bz2
Source27: %src_package_name-2.6.27-%src_2_6_27_version.tar.bz2
Source28: %src_package_name-2.6.28-%src_2_6_28_version.tar.bz2
Source29: %src_package_name-2.6.29-%src_2_6_29_version.tar.bz2

Conflicts: linux-cifs

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

%install
mkdir -p %buildroot%_sysconfdir
echo DATADIR=%_datadir/%name > %buildroot%_sysconfdir/%name.conf
echo SRC_DIR=%_usrsrc/%name-%version >> %buildroot%_sysconfdir/%name.conf
echo MODULENAME=%name >> %buildroot%_sysconfdir/%name.conf
echo MODULEVERSION=%version >> %buildroot%_sysconfdir/%name.conf

mkdir -p %buildroot%_datadir/%name
install -m644 buildmodule.sh %buildroot%_datadir/%name
install -m644 functions.sh %buildroot%_datadir/%name

mkdir -p %buildroot%_initdir
install -m755 %name %buildroot%_initdir
install -m755 %name.outformat %buildroot%_initdir

%define etercifs_src %_datadir/%name/sources

mkdir -p %buildroot/%etercifs_src
cp %SOURCE1 %buildroot/%etercifs_src/%src_package_name-legacy-%src_legacy_version.tar.bz2
for N in `seq 17 22`
do
  ln -s %src_package_name-legacy-%src_legacy_version.tar.bz2 %buildroot/%etercifs_src/%src_package_name-2.6.$N-%src_legacy_version.tar.bz2
done
cp %SOURCE16 %buildroot/%etercifs_src/%src_package_name-2.6.16-%src_2_6_16_version.tar.bz2
cp %SOURCE23 %buildroot/%etercifs_src/%src_package_name-2.6.23-%src_2_6_23_version.tar.bz2
cp %SOURCE24 %buildroot/%etercifs_src/%src_package_name-2.6.24-%src_2_6_24_version.tar.bz2
cp %SOURCE25 %buildroot/%etercifs_src/%src_package_name-2.6.25-%src_2_6_25_version.tar.bz2
cp %SOURCE26 %buildroot/%etercifs_src/%src_package_name-2.6.26-%src_2_6_26_version.tar.bz2
cp %SOURCE27 %buildroot/%etercifs_src/%src_package_name-2.6.27-%src_2_6_27_version.tar.bz2
cp %SOURCE28 %buildroot/%etercifs_src/%src_package_name-2.6.28-%src_2_6_28_version.tar.bz2
cp %SOURCE29 %buildroot/%etercifs_src/%src_package_name-2.6.29-%src_2_6_29_version.tar.bz2

%post
%post_service %name

%preun
%preun_service %name

%files
%config %_sysconfdir/%name.conf
%_datadir/%name
%_initdir/%name
%_initdir/%name.outformat
%doc README.ETER AUTHORS CHANGES README TODO

%changelog
* Mon Mar 30 2009 Konstantin Baev <kipruss@altlinux.org> 4.3.0-alt1
- add sources/2.6.29
- Fix bugs Eter#1185 and Eter#3660 (F_GETLK problem connected with wrong returning file_lock structure)
- Fix bugs Eter#3237 (problem remove lock at Windows share)
- Refactoring code, which solved kmem_cache_destroy problem
- Correct message about loaded version of etercifs module (in status command)
- Some bugfixes

* Thu Mar 19 2009 Konstantin Baev <kipruss@altlinux.org> 4.2.1-alt1
- Fix bug Eter#3638 (solve some DKMS troubles)
- update sources/2.6.27 (up to 2.6.27.20)
- update sources/2.6.28 (up to 2.6.28.8)

* Thu Mar 10 2009 Konstantin Baev <kipruss@altlinux.org> 4.2.0-alt1
- Send SMB flush in cifs_fsync [Backport from CIFS devel git]
- Remove oplock part of Etersoft patches
- Fix bug Eter#3239 (problem while mkdir -p d1/d2)
- Fix bug Eter#3626 (cifs kmem_cache_destroy problem)

* Wed Feb 11 2009 Konstantin Baev <kipruss@altlinux.org> 4.1.2-alt1
- CIFS_VERSION in module replaced by version of etercifs package
- update sources/2.6.27 (up to 2.6.27.15)
- update sources/2.6.28 (up to 2.6.28.4)

* Mon Jan 19 2009 Konstantin Baev <kipruss@altlinux.org> 4.1.1-alt1
- remove deprecated code from legacy sources
- add sources/2.6.16 from SLES10SP2 kernel with Etersoft patches (Eter#3249)
- add checking availability GNU make utility (Eter#3265)
- update sources/2.6.28 (up to 2.6.28.1)

* Mon Jan 12 2009 Konstantin Baev <kipruss@altlinux.org> 4.1.0-alt1
- add sources/2.6.28

* Fri Dec 26 2008 Konstantin Baev <kipruss@altlinux.org> 4.0.1-alt3
- fix build in kernels 2.6.18 - 2.6.24 (may be broken after adding option "forcemand")

* Thu Dec 18 2008 Konstantin Baev <kipruss@altlinux.org> 4.0.1-alt2
- minor design changes in sources code
- add docs

* Tue Dec 16 2008 Konstantin Baev <kipruss@altlinux.org> 4.0.1-alt1
- update all sources: add code, that fixing bug Eter#2929
- update sources/2.6.27 (up to 2.6.27.9)

* Tue Dec 09 2008 Konstantin Baev <kipruss@altlinux.org> 4.0.0-alt2
- update all sources: add mount option "forcemand"
- update sources/2.6.27 (up to 2.6.27.8)
- additional checking for existence etercifs kernel module sources for current kernel
- add symlinks for kernel sources 2.6.16 and 2.6.17
- fix RT ticket 7479 and bug Eter#2898
- add checking the kernel configuration

* Thu Dec 04 2008 Konstantin Baev <kipruss@altlinux.org> 4.0.0-alt1
- test build: add mount option "forcemandatorylock" aka "forcemand"

* Tue Nov 18 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt7
- Minor bugfix

* Tue Nov 18 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt6
- fixed bug Eter#2936

* Tue Nov 11 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt5
- removed default parameter '-o mount' for mount fstab records

* Tue Nov 11 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt4
- removed parameter (noreplace) for config file

* Tue Nov 11 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt3
- add starting module after building (if module not exist)

* Fri Nov 07 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt2
- fix building module on Ubuntu

* Thu Nov 06 2008 Konstantin Baev <kipruss@altlinux.org> 3.8.0-alt1
- fix building module with dkms
- add config file /etc/etercifs.conf

* Wed Nov 05 2008 Konstantin Baev <kipruss@altlinux.org> 3.7.0-alt2
- delete last change (building module on installing rpm)
- remove kernel_src.list and distr_vendor
- code refactoring near finction.sh and buildmodule.sh
- while fixing Eter#2782 added option 'testbuild' in rc-script:
  now able the command:
    service etercifs testbuild
- fix bug Eter#2783

* Thu Oct 30 2008 Konstantin Baev <kipruss@altlinux.org> 3.7.0-alt1
- Add building module on installing rpm

* Thu Oct 30 2008 Konstantin Baev <kipruss@altlinux.org> 3.6.1-alt1
- update sources/2.6.23 (Fixed bug Eter#2773)

* Mon Oct 27 2008 Konstantin Baev <kipruss@altlinux.org> 3.6-alt1
- update sources/2.6.27 (up to 2.6.27.4)

* Thu Oct 23 2008 Konstantin Baev <kipruss@altlinux.org> 3.5-alt1
- update sources/2.6.25 (up to 2.6.25.19)
- update sources/2.6.26 (up to 2.6.26.7)
- update sources/2.6.27 (up to 2.6.27.3)
- minor code refactoring

* Tue Oct 21 2008 Konstantin Baev <kipruss@altlinux.org> 3.4-alt1
- Fix error while building module in MOPSLinux
- update sources/2.6.27

* Fri Oct 10 2008 Konstantin Baev <kipruss@altlinux.org> 3.3-alt1
- move sources into etercifs rmp package
- delete Requires
- delete Spec part for ALT Linux with BuildRequires
- Url fixed
- update sources/2.6.25
- add sources/2.6.24
- add sources/2.6.23
- add sources/2.6.26
- add sources/2.6.27

* Thu Oct 09 2008 Konstantin Baev <kipruss@altlinux.org> 3.2-alt2
- remove Requires: rpm-build-compat
- add distr_vendor into package

* Wed Oct 08 2008 Konstantin Baev <kipruss@altlinux.org> 3.2-alt1
- remove disableing LinuxExtensions (bug Eter#2563)
- now package etercifs is not similar linux-cifs

* Wed Oct 08 2008 Konstantin Baev <kipruss@altlinux.org> 3.1-alt3
- Minor bugfix

* Wed Oct 08 2008 Konstantin Baev <kipruss@altlinux.org> 3.1-alt2
- Fixed part 2 of bug Eter#2553

* Tue Oct 07 2008 Konstantin Baev <kipruss@altlinux.org> 3.1-alt1
- Fixed part 1 of bug Eter#2553
- Added usage Generic for etercifs sources

* Wed Oct 01 2008 Konstantin Baev <kipruss@altlinux.org> 3.0-alt1
- Up version to 2.0
- changed flag in /fs/cifs/file.c
- changed package name and service name to etercifs
- added Conflicts

* Thu Sep 25 2008 Konstantin Baev <kipruss@altlinux.org> 2.0-alt1
- Up version to 2.0

* Thu Sep 25 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt9
- Removed experimental code

* Wed Sep 24 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt8
- For compatibility Serial replaced by Epoch

* Wed Sep 24 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt7
- For compatibility with Ubuntu command service replaced by macros

* Fri Sep 19 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt6
- Remove BuildRequires and  add requires - rpm-build-compat

* Tue Sep 16 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt5
- Symlinks changed to local

* Fri Sep 05 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt4
- Minor bugfix in spec

* Fri Sep 05 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt3
- Added forgotten part (post and preun) of spec (and modified)

* Thu Sep 04 2008 Konstantin Baev <kipruss@altlinux.org> 1:1.0-alt2
- fixed build problem on kernel 2.6.18

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
