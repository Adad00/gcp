#!/bin/bash

#
# Clone VM with additional disk script
# by: Adad O and Jorge P
# Version: 0.0.0.1 Alpha
# Date: 10/16/2019@12:00 CDT
# Category: Infra
# Type: Skeleton

#
# Client area: please set this variables.
#

# VM Name
vm_nm=

# Origin zone
or_zone=

# Destination zone
dt_zone=

# Machine type
mch_type=

# Reservation affinity
res_affn=any

#####################################################
#       Start process and internal variables        #
#####################################################

# Randon string (for ID)
randm = $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-8} | head -n 1)

# Disk name
disk_nm=
snpsht_nm=${disk_nm}-snap-${randm}

clear

#
# Test if we receive the VM Name
#

if [[ test -z "${vm_nm}" ]] || [[ test -z "${or_zone}" ]] || [[ test -z "${dt_zone}" ]]
then
      echo "One or more required variables are empty, the script cannot continue."
else
  
    #
    # Add the Disk Name to a var
    #

    disk_nm=$(gcloud compute instances describe ${vm_nm} --zone=${or_zone} | grep -C 5 "boot: false" | grep deviceName: | awk -F: '{print $2}')
    
    #
    # Find and save the boot disk from the selected VM
    #
    boot_disk_nm=$(gcloud compute instances describe ${vm_nm} --zone=${or_zone} | grep -C 5 "boot: true" | grep deviceName: | awk -F: '{print $2}')

    #
    # Create the disk snap into the destination zone
    #
    snpsht_nm=${vm_nm}-bootreplicadisk
    gcloud compute disks snapshot ${boot_disk_nm} --zone=${or_zone} --snapshot-names=${vm_nm}-bootdisk

    #
    # Execute the snapshot (set the snapshot name as well)
    #
    gcloud compute disks create ${snapsht_nm} --zone=${dt_zone} --source-snapshot=${vm_nm}-bootdisk
    
    #
    # Create the VM with a boot disk already created and add the additional disk created from the snapshot
    #
    data_dsk_nm=${vm_nm}-datadisk
    data_rpl_nm=${vm_nm}-datareplicadisk
    gcloud beta compute instances create ${vm_nm}-replica --zone=${dt_zone} --machine-type=${mch_type} --disk=name=${snpsht_nm},device-name=${snpsht_nm},mode=rw,boot=yes,auto-delete=no --create-disk source-snapshot=${data_dsk_nm},name=${data_dsk_nm},device-name=${data_rpl_nm},auto-delete=no,mode=rw --reservation-affinity=${res_affn}
fi
