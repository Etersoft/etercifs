/*
 *  fs/cifs/cifs_dfs_ref.c
 *
 *   Copyright (C) International Business Machines  Corp., 2007
 *   Author(s): Steve French (sfrench@us.ibm.com)
 *              Igor Mammedov (niallain@gmail.com)
 *   Contains the CIFS DFS upcall routines
 *
 *   This library is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as published
 *   by the Free Software Foundation; either version 2.1 of the License, or
 *   (at your option) any later version.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
 *   the GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public License
 *   along with this library; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#include <linux/dcache.h>
#include <linux/mount.h>
#include <linux/namei.h>
#include <linux/vfs.h>
#include <linux/fs.h>

#include "cifsfs.h"
#include "cifspdu.h"
#include "cifsglob.h"
#include "cifsproto.h"
#include "cifs_debug.h"
#include "cifs_fs_sb.h"

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
#ifdef CONFIG_CIFS_EXPERIMENTAL
LIST_HEAD(cifs_dfs_automount_list);

static void cifs_resolver_describe(const struct key *key, struct seq_file *m)
{
	cFYI(1, ("%s: key->description: %s", __FUNCTION__,  key->description ));
	seq_puts(m, key->description);
	seq_printf(m, ": %u", key->datalen);
}

static int cifs_resolver_match(const struct key *key, const void *description)
{
	cFYI(1, ("%s: key->description: %s ; desc: %s ", __FUNCTION__,
		key->description, (char *)description ));
	return strcmp(key->description, description) == 0;
}

static int cifs_resolver_instantiate(struct key *key, const void *data,
				     size_t datalen)
{
	char *ip = NULL;
	int rc;
	struct in_addr ip_addr;

	/* convert dot ip addr to numeric form */
	/* BB Do we have to pass datalen? Are we guaranteed that the key
	 * is null terminated? */
	rc = cifs_inet_pton(AF_INET, (char *)data, &(ip_addr.s_addr));
	if (rc <= 0) {
		ip = kmalloc(datalen+1, GFP_KERNEL);
		if (ip == NULL) {
			return -ENOMEM;
		}
		strncpy( ip, (char *)data, datalen);
		ip[datalen] = 0;

		cFYI(1, ("%s: failed to convert ip to binary: %s",
			__FUNCTION__, ip));
		kfree(ip);
		rc = -EINVAL;
		return rc;
	}
	rc = 0;
	key->payload.value = ip_addr.s_addr;
	return rc;
}

struct key_type key_type_cifs_resolver =
{
	.name        = "cifs_resolver",
	.def_datalen = sizeof(struct in_addr),
	.describe    = cifs_resolver_describe,
	.instantiate = cifs_resolver_instantiate,
	.match       = cifs_resolver_match,
};


int
cifs_resolve_server_name_to_ip(const char *unc, struct in_addr *ip_addr) {
	int rc = -EAGAIN;
	struct key *rkey;
	char *name;
	int len;

	if ((!ip_addr) || (!unc)) {
		return -EINVAL;
	}

	/* search for server name delimiter */
	len = strlen( unc);
	if (len < 3) {
		cFYI(1, ("%s: unc is too short: %s",
			 __FUNCTION__, unc ));
		return -EINVAL;
	}
	len -= 2;
	name = memchr(unc+2, '\\', len);
	if (!name) {
		cFYI(1, ("%s: probably server name is whole unc: %s",
			 __FUNCTION__, unc ));
	} else {
		len = (name - unc) - 2/* leading // */;
	}

	name = kmalloc( len+1, GFP_KERNEL);
	if (name == NULL) {
		rc = -ENOMEM;
		return rc;
	}
	memcpy( name, unc+2, len);
	name[len] = 0;

	rkey = request_key(&key_type_cifs_resolver, name, "");
	if (!IS_ERR(rkey)) {
		ip_addr->s_addr = rkey->payload.value;
		cFYI(1, ("%s: resolved: %s to %u.%u.%u.%u", __FUNCTION__,
					rkey->description,
					NIPQUAD(ip_addr->s_addr)
			));

		key_put(rkey);
		rc = 0;
	} else {
		cERROR(1, ("%s: unable to resolve: %s", __FUNCTION__, name));
	}

	kfree(name);
	return rc;
}


char *
cifs_get_share_name(const char *node_name)
{
	int len;
	char *UNC;
	char *pSep;

	len = strlen(node_name);
	UNC = kmalloc(len+2 /*for term null and additional \ if it's missed */,
			 GFP_KERNEL);
	if (!UNC) {
		return NULL;
	}

	/* get share name and server name */
	if (node_name[1] != '\\'){
		UNC[0] = '\\';
		strncpy(UNC+1, node_name, len);
		len++;
		UNC[len] = 0;
	} else {
		strncpy(UNC, node_name, len);
		UNC[len] = 0;
	}

	/* find server name end */
	pSep = memchr(UNC+2, '\\', len-2);
	if (!pSep) {
		cERROR(1, ("%s: no server name end in node name: %s",
			__FUNCTION__, node_name ));
		kfree(UNC);
		return NULL;
	}

	/* find sharename end */
	pSep++;
	pSep = memchr(UNC+(pSep-UNC), '\\', len-(pSep-UNC));
	if (!pSep) {
		cERROR(1, ("%s:2 cant find share name in node name: %s",
			__FUNCTION__, node_name ));
		kfree(UNC);
		return NULL;
	}
	/* trim path up to sharename end
	 *          * now we have share name in UNC */
	*pSep = 0;
	len = pSep-UNC;

	return UNC;
}


struct vfsmount *cifs_dfs_do_refmount(const struct vfsmount *mnt_parent,
				      struct dentry *dentry, char *ref_unc)
{
	int rc;
	struct cifs_sb_info *cifs_sb;
	struct sockaddr_in sin_server;
	struct vfsmount *mnt = ERR_PTR(-ENOENT);
	char *mountdata;
	int md_len;
	char *devname;
	char *tkn_e;
	char srvIP[16];
	char sep = ',';
	int off, noff;

	cFYI(1, ("in %s", __FUNCTION__ ));

	cifs_sb = CIFS_SB(dentry->d_inode->i_sb);

	if ( cifs_sb->mountdata == NULL ) {
		return ERR_PTR(-EINVAL);
	}

	devname = cifs_get_share_name(ref_unc);
	rc = cifs_resolve_server_name_to_ip( devname, &(sin_server.sin_addr));
	snprintf(srvIP, sizeof(srvIP), "%u.%u.%u.%u",
			NIPQUAD(sin_server.sin_addr));
	if (rc != 0) {
		if (devname) kfree(devname);
		cERROR(1, ("%s: failed to resolve server part of %s to IP",
			  __FUNCTION__, devname ));
		rc = -EINVAL;
		return ERR_PTR(rc);
	}
	srvIP[sizeof(srvIP)-1] = '\0';
	md_len = strlen(cifs_sb->mountdata) + sizeof(srvIP) +
			strlen(ref_unc) + 3;
	mountdata = kzalloc(md_len+1, GFP_KERNEL);

	/* copy all options except unc,ip,prefixpath */
	off = 0;
	if (strncmp(cifs_sb->mountdata, "sep=", 4) == 0) {
			sep = cifs_sb->mountdata[4];
			strncpy(mountdata, cifs_sb->mountdata, 5);
			off += 5;
	}
	while ( (tkn_e = strchr(cifs_sb->mountdata+off, sep)) ) {
		noff = (tkn_e - (cifs_sb->mountdata+off)) + 1;
		if (strnicmp(cifs_sb->mountdata+off, "unc=", 4) == 0) {
			off += noff;
			continue;
		}
		if (strnicmp(cifs_sb->mountdata+off, "ip=", 3) == 0) {
			off += noff;
			continue;
		}
		if (strnicmp(cifs_sb->mountdata+off, "prefixpath=", 3) == 0) {
			off += noff;
			continue;
		}
		strncat(mountdata, cifs_sb->mountdata+off, noff);
		off += noff;
	}
	strcat(mountdata, cifs_sb->mountdata+off);
	mountdata[md_len] = '\0';
	strcat(mountdata, ", ip="); strcat(mountdata, srvIP);
	strcat(mountdata, ", unc="); strcat(mountdata, devname);
	/* find prefixpath */
	tkn_e = strchr(ref_unc+2, '\\');
	if ( tkn_e ) {
		tkn_e = strchr(tkn_e+1, '\\');
		if ( tkn_e ) {
			strcat(mountdata, ",prefixpath=");
			strcat(mountdata, tkn_e);
		}
	}

	/*cFYI(1,("%s: old mountdata: %s", __FUNCTION__,cifs_sb->mountdata));*/
	/*cFYI(1, ("%s: new mountdata: %s", __FUNCTION__, mountdata ));*/

	mnt = vfs_kern_mount(&cifs_fs_type, 0, devname, mountdata);
	if (devname)
		kfree(devname);
	if (mountdata)
		kfree(mountdata);
	cFYI(1, ("leaving %s", __FUNCTION__ ));
	return mnt;
}

static char *build_full_dfs_path_from_dentry(struct dentry *dentry)
{
	char *full_path = NULL;
	char *search_path;
	char *tmp_path;
	size_t l_max_len;
	struct cifs_sb_info *cifs_sb;

	if ( dentry->d_inode == NULL ) {
		return NULL;
	}

	cifs_sb = CIFS_SB(dentry->d_inode->i_sb);

	if ( cifs_sb->tcon == NULL ) {
		return NULL;
	}

	search_path = build_path_from_dentry(dentry);
	if (search_path == NULL) {
		return NULL;
	}

	if (cifs_sb->tcon->Flags & 0x2) {
		/* we should use full path name to correct working with DFS */
		l_max_len = strnlen(cifs_sb->tcon->treeName, MAX_TREE_SIZE + 1)
				     + strnlen(search_path, MAX_PATHCONF) + 1;
		tmp_path = kmalloc(l_max_len, GFP_KERNEL);
		if (tmp_path == NULL) {
			kfree(search_path);
			return NULL;
		}
		strncpy(tmp_path, cifs_sb->tcon->treeName, l_max_len);
		strcat(tmp_path, search_path);
		tmp_path[l_max_len-1] = 0;
		full_path = tmp_path;
		kfree(search_path);
	} else {
		full_path = search_path;
	}
	return full_path;
}

static void *cifs_dfs_follow_mountpoint(struct dentry *dentry,
					struct nameidata *nd)
{
	DFS_INFO3_PARAM *referrals = NULL;
	unsigned int num_referrals = 0;
	struct cifs_sb_info *cifs_sb;
	struct cifsSesInfo *ses;
	char *full_path = NULL;
	int xid, i;
	int rc = 0;
	struct vfsmount *mnt = ERR_PTR(-ENOENT);

	cFYI(1, ("in %s", __FUNCTION__ ));
	BUG_ON(IS_ROOT(dentry));

	xid = GetXid();

	dput(nd->dentry);
	nd->dentry = dget(dentry);
	if (d_mountpoint(nd->dentry)) {
		goto out_follow;
	}

	if ( dentry->d_inode == NULL ) {
		rc = -EINVAL;
		goto out_err;
	}

	cifs_sb = CIFS_SB(dentry->d_inode->i_sb);
	ses = cifs_sb->tcon->ses;

	if ( !ses ) {
		rc = -EINVAL;
		goto out_err;
	}

	full_path = build_full_dfs_path_from_dentry(dentry);
	if ( full_path == NULL ) {
		rc = -ENOMEM;
		goto out_err;
	}

	rc = get_dfs_path(xid, ses , full_path, cifs_sb->local_nls,
			&num_referrals, &referrals,
			cifs_sb->mnt_cifs_flags & CIFS_MOUNT_MAP_SPECIAL_CHR);

	for (i = 0; i < num_referrals; i++) {
		cFYI(1, ("%s: ref path: %s", __FUNCTION__,
			 referrals[i].path_name));
		cFYI(1, ("%s: node path: %s", __FUNCTION__,
			 referrals[i].node_name ));
		cFYI(1, ("%s: fl: %hd, serv_type: %hd, ref_flags: %hd, "
			 "path_consumed: %hd", __FUNCTION__,
			 referrals[i].flags, referrals[i].server_type,
			 referrals[i].ref_flag, referrals[i].PathConsumed));

		/* connect to storage node */
		if (referrals[i].flags & DFSREF_STORAGE_SERVER) {
			int len;
			len = strlen(referrals[i].node_name);
			if (len < 2) {
				cERROR(1, ("%s: Net Address path too short: %s",
					__FUNCTION__, referrals[i].node_name ));
				rc = -EINVAL;
				goto out_err;
			} else {
				mnt = cifs_dfs_do_refmount(nd->mnt,
						nd->dentry,
						referrals[i].node_name);
				cFYI(1, ("%s: cifs_dfs_do_refmount:%s , mnt:%p",
					 __FUNCTION__,
					 referrals[i].node_name, mnt));
				if ( !rc ) {
					/* have server so stop here & return */
					break;
				}
			}
		}
	}

	rc = PTR_ERR(mnt);
	if (IS_ERR(mnt))
		goto out_err;

	mntget(mnt);
	rc = do_add_mount(mnt, nd, nd->mnt->mnt_flags,
			  &cifs_dfs_automount_list);
	if (rc < 0) {
		mntput(mnt);
		if (rc == -EBUSY)
			goto out_follow;
		goto out_err;
	}
	mntput(nd->mnt);
	dput(nd->dentry);
	nd->mnt = mnt;
	nd->dentry = dget(mnt->mnt_root);

out:
	FreeXid(xid);
	free_dfs_info_array(referrals, num_referrals);
	cFYI(1, ("leaving %s", __FUNCTION__ ));
	return ERR_PTR(rc);
out_err:
	if ( full_path ) kfree(full_path);
	path_release(nd);
	goto out;
out_follow:
	while (d_mountpoint(nd->dentry) && follow_down(&nd->mnt, &nd->dentry))
		;
	rc = 0;
	goto out;
}

struct inode_operations cifs_dfs_referral_inode_operations = {
	.follow_link = cifs_dfs_follow_mountpoint,
};
#endif /* CONFIG_CIFS_EXPERIMENTAL */
#endif /* Kernel version 2.6.18 or higher */