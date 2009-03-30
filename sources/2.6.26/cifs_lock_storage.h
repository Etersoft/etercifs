/*
 *   fs/cifs/cifs_lock_storage.h
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

#ifndef CIFS_LOCK_STORAGE
#define CIFS_LOCK_STORAGE

/* creating lock tree */
void cifs_lock_storage_init(void);

/* inserting lock */
int cifs_lock_storage_add_lock(__u32 pid, unsigned long inodeId, __u16 fid, __u64 offset, __u64 len, __u8 type);

/* deleting lock */
int cifs_lock_storage_del_lock(int xid, struct cifsTconInfo *pTcon, __u32 pid, unsigned long inodeId, __u64 offset, __u64 len, __u8 type);

#endif
