#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

clear

echo -e "\n !!WARNING!! If you continue, the storage drive will be completely erased! Are you sure you want to continue?"
echo "Type 'yes' to continue, type anything else to abort"
read ANSWER

if [ $ANSWER == 'yes' ]
then
    #Format the disk and partition
    sgdisk -Z /dev/sda
    echo -e "\n~~Disk has been wiped~~"
    sgdisk -N=0 /dev/sda
    echo -e "\n~~Partition has been created~~"
    DISKID=`ls -l /dev/disk/by-id | awk 'NR==3{print $9}'`
    mkfs.ext4 /dev/sda1 -F

    #Mount the disk partition
    mkdir /mnt/storage
    mount /dev/sda1 /mnt/storage

    #Add to Fstab if not already done
    if ! grep -q 'storage-disk' /etc/fstab ; then
        echo '# storage-disk' >> /etc/fstab
        echo '/dev/sda1  /mnt/storage  ext4  defaults  0  0' >> /etc/fstab
    fi

else
echo -e "\n~~Installation aborted~~"
exit
fi