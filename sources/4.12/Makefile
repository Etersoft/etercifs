#
# Makefile for Linux CIFS VFS client 
#
obj-$(CONFIG_CIFS) += etercifs.o

etercifs-y := cifsfs.o cifssmb.o cifs_debug.o connect.o dir.o file.o inode.o \
	  link.o misc.o netmisc.o smbencrypt.o transport.o asn1.o \
	  cifs_unicode.o nterr.o cifsencrypt.o \
	  readdir.o ioctl.o sess.o export.o smb1ops.o winucase.o

etercifs-$(CONFIG_CIFS_XATTR) += xattr.o
etercifs-$(CONFIG_CIFS_ACL) += cifsacl.o

etercifs-$(CONFIG_CIFS_UPCALL) += cifs_spnego.o

etercifs-$(CONFIG_CIFS_DFS_UPCALL) += dns_resolve.o cifs_dfs_ref.o

etercifs-$(CONFIG_CIFS_FSCACHE) += fscache.o cache.o

etercifs-$(CONFIG_CIFS_SMB2) += smb2ops.o smb2maperror.o smb2transport.o \
			    smb2misc.o smb2pdu.o smb2inode.o smb2file.o
