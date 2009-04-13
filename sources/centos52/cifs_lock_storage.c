/*
 *   fs/cifs/cifs_lock_storage.c
 *
 *   lock tree operations that provide posix behaviour on windows server
 *
 *   Author(s): Pavel Shilovsky (piastryyy@gmail.com), Copyright (C) 2009.
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
 *
 */

#include <linux/ctype.h>
#include <linux/kthread.h>
#include <linux/random.h>
#include "cifspdu.h"
#include "cifsglob.h"
#include "cifsproto.h"
#include "cifs_unicode.h"
#include "cifs_debug.h"
#include "cifs_fs_sb.h"
#include "cifs_lock_storage.h"

struct cifsPidTreeLock {
	struct list_head lock_list;
	__u8 type;
	__u64 offset;
	__u64 len;
	__u16 fid;
	unsigned long inodeId;
};

struct cifsPidTree {
	struct cifsPidTree *left, *right;
	__u64 priority;
	__u32 pid;
	struct list_head lock_list;
};

static struct cifsPidTree *LOCK_STORAGE;
static struct mutex storage_mutex;

static __u32 cifsRandStart;

static __u32 cifs_random(void)
{
	return cifsRandStart = (8253729 * cifsRandStart + 2396403);
}

void cifs_lock_storage_init(void)
{
	mutex_init(&storage_mutex);
	LOCK_STORAGE = NULL;
	cifsRandStart = jiffies;
}

static int vertex_init(struct cifsPidTree **root, __u32 pid)
{
	(*root) = kmalloc(sizeof(struct cifsPidTree), GFP_KERNEL);
	if ((*root) == NULL) {
		return -ENOMEM;
	}
	(*root)->pid = pid;
	(*root)->left = (*root)->right = NULL;
	(*root)->priority = ((cifs_random() << 16) ^ cifs_random());
	INIT_LIST_HEAD(&(*root)->lock_list);
	return 0;
}

static void cifs_pid_tree_split(struct cifsPidTree *root, struct cifsPidTree **left, struct cifsPidTree **right, __u32 pid)
{
	if (!root) {
		(*left) = (*right) = NULL;
		return;
	}

	if (pid <= root->pid) {
		(*right) = root;
		cifs_pid_tree_split(root->left, left, &((*right)->left), pid);
	} else {
		(*left) = root;
		cifs_pid_tree_split(root->right, &((*left)->right), right, pid);
	}
}

static struct cifsPidTree * cifs_pid_tree_merge(struct cifsPidTree *left, struct cifsPidTree *right)
{
	struct cifsPidTree *result = NULL;
	if (!left) {
		return right;
	}
	if (!right) {
		return left;
	}
	if (left->priority <= right->priority) {
		result = right;
		result->left = cifs_pid_tree_merge(left, right->left);
	} else {
		result = left;
		result->right = cifs_pid_tree_merge(left->right, right);
	}
	return result;
}

static struct cifsPidTree ** cifs_pid_tree_find_pid(struct cifsPidTree **root, __u32 pid)
{
	if (!(*root)) {
		return root;
	}
	if (pid == (*root)->pid) {
		return root;
	} else if (pid < (*root)->pid) {
		return cifs_pid_tree_find_pid(&((*root)->left), pid);
	} else {
		return cifs_pid_tree_find_pid(&((*root)->right), pid);
	}
}

static int __cifs_lock_storage_add_lock(struct cifsPidTree **root, __u32 pid, unsigned long inodeId, __u16 fid, __u64 offset, __u64 len, __u8 type)
{
	struct cifsPidTreeLock *new_lock = NULL;
	int rc = 0;
	struct cifsPidTree **exist = NULL;
	exist = cifs_pid_tree_find_pid(root, pid);
	new_lock = kmalloc(sizeof(struct cifsPidTreeLock), GFP_KERNEL);
	if (new_lock == NULL) {
		return -ENOMEM;
	}
	new_lock->offset = offset;
	new_lock->len = len;
	new_lock->type = type;
	new_lock->fid = fid;
	new_lock->inodeId = inodeId;
	if (!(*exist)) {
		struct cifsPidTree *left = NULL, *right = NULL, *new_item = NULL;
		rc = vertex_init(&new_item, pid);
		if (rc) {
			kfree(&new_lock);
			return rc;
		}
		list_add(&new_lock->lock_list, &new_item->lock_list);
		cifs_pid_tree_split((*root), &left, &right, pid);
		(*root) = cifs_pid_tree_merge(left, new_item);
		(*root) = cifs_pid_tree_merge((*root), right);
	} else {
		list_add(&new_lock->lock_list, &(*exist)->lock_list);
	}
	return rc;
}

static int __cifs_lock_storage_del_lock(int xid, struct cifsTconInfo *pTcon, struct cifsPidTree **root,
		__u32 pid, unsigned long inodeId, __u64 offset, __u64 len, __u8 type)
{
	struct cifsPidTree **exist;
	int rc = 0;
	struct cifsPidTreeLock *li, *tmp;
	exist = cifs_pid_tree_find_pid(root, pid);
	if (!(*exist)) {
		return -1;
	}
	list_for_each_entry_safe(li, tmp, &(*exist)->lock_list, lock_list) {
		if (li->offset >= offset && (li->offset+li->len <= offset+len) && (inodeId == li->inodeId)) {
			int tmp_rc = CIFSSMBLock(xid, pTcon,
				li->fid,
				li->len, li->offset,
				1, 0, li->type, FALSE);
			if (tmp_rc) {
				rc = tmp_rc;
			} else {
				list_del(&li->lock_list);
				kfree(li);
			}
		}
	}
	if (list_empty(&((*exist)->lock_list))) {
		struct cifsPidTree *temp;
		temp = (*exist);
		(*exist) = cifs_pid_tree_merge((*exist)->left, (*exist)->right);
		kfree(temp);
	}
	return rc;
}

int cifs_lock_storage_add_lock(__u32 pid, unsigned long inodeId, __u16 fid, __u64 offset, __u64 len, __u8 type)
{
	int rc;
	mutex_lock(&storage_mutex);
	rc = __cifs_lock_storage_add_lock(&LOCK_STORAGE, pid, inodeId, fid, offset, len, type);
	mutex_unlock(&storage_mutex);
	return rc;
}

int cifs_lock_storage_del_lock(int xid, struct cifsTconInfo *pTcon, __u32 pid, unsigned long inodeId, __u64 offset, __u64 len, __u8 type)
{
	int rc;
	mutex_lock(&storage_mutex);
	rc = __cifs_lock_storage_del_lock(xid, pTcon, &LOCK_STORAGE, pid, inodeId, offset, len, type);
	mutex_unlock(&storage_mutex);
	return rc;
}
