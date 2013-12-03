#!/bin/bash -e

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
HOST="<%= @host %>"
ORIG_VOLUME="<%= @source %>"
KEEP=2
BACKUP_MNT=/raid-backup
RDIFF_BACKUP_OPTS='<%= @options %>'
RDIFF_DEST=<%= @destination %>
VG_NAME=$(expr "$ORIG_VOLUME" : "^/.*/\(.*\)/.*$")
LV_NAME=$(expr "$ORIG_VOLUME" : "^/.*/\(.*\)$")
SNAPSHOTS=$(lvs | perl -ne 'print "$1\n" if /'${LV_NAME}'-snap(\d+)/' | sort -r)

for i in $SNAPSHOTS; do
	MOUNTPOINT="/dev/mapper/${VG_NAME}-${LV_NAME}--snap${i}"
	if (grep -q "^${MOUNTPOINT} " /proc/mounts); then
		umount ${ORIG_VOLUME}-snap${i}
	fi
done
for i in $SNAPSHOTS; do
	if [ "${i}" -ge "${KEEP}" ]; then
		lvremove -f ${ORIG_VOLUME}-snap${i} >/dev/null
	else
		lvrename ${ORIG_VOLUME}-snap${i} ${ORIG_VOLUME}-snap$((${i}+1)) >/dev/null
	fi
done
lvcreate -s ${ORIG_VOLUME} -l $((10/$KEEP))%VG --name ${ORIG_VOLUME}-snap1 >/dev/null

mkdir -p ${BACKUP_MNT}
mount -o nouuid,inode64,nobarrier,ro ${ORIG_VOLUME}-snap1 ${BACKUP_MNT}
ssh root@$HOST "mkdir -p ${RDIFF_DEST}"
rdiff-backup ${RDIFF_BACKUP_OPTS} ${BACKUP_MNT} root@$HOST::${RDIFF_DEST} >/dev/null
rdiff-backup --remove-older-than 4W --force root@$HOST::${RDIFF_DEST} >/dev/null
umount ${BACKUP_MNT}
