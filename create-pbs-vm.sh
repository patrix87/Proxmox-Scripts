#!/bin/bash
# Set the variables
id=5100
name=pbs
storage=ha-pbs-1tb-01
iso=/var/lib/vz/template/iso/proxmox-backup-server_3.4-1.iso
cores=4
memory=4096
disk_size=250

# Create a new VM with the specified ID and name, using the host CPU type
qm create $id --name $name --cpu host --cores $cores --memory $memory --net0 virtio,bridge=vmbr0
# Set the SCSI controller type to VirtIO SCSI single
qm set $id --scsihw virtio-scsi-single
# Create a SCSI disk with the specified size and raw format
qm set $id --scsi0 ${storage}:${disk_size},format=raw
# Set the CD-ROM drive to use the PBS ISO
qm set $id --ide2 $iso,media=cdrom
# Set the boot order to boot from the CD-ROM first
qm set $id --boot order='ide2;scsi0'
# Enable the QEMU agent
qm set $id --agent enabled=1
# Set the OS type to Windows 11
qm set $id --ostype other
# Allow hotplugging of disks, network interfaces, and USB devices
qm set $id --hotplug disk,network,usb
# create a serial port and set it as the primary display
qm set "$id" --serial0 socket --vga serial0
# Display the VM configuration
qm config $id
