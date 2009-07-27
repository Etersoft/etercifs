#
# Makefile for Linux CIFS VFS client 
#
obj-$(CONFIG_CIFS) += etercifs.o

etercifs-y := cifsfs.o cifssmb.o cifs_debug.o connect.o dir.o file.o inode.o \
	  link.o misc.o netmisc.o smbdes.o smbencrypt.o transport.o asn1.o \
	  md4.o md5.o cifs_unicode.o nterr.o xattr.o cifsencrypt.o \
	  readdir.o ioctl.o sess.o export.o cifsacl.o

etercifs-$(CONFIG_CIFS_UPCALL) += cifs_spnego.o

etercifs-$(CONFIG_CIFS_DFS_UPCALL) += dns_resolve.o cifs_dfs_ref.o
