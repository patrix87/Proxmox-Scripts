#!/bin/bash
# Set the variables
id=9001
name=windows-2025
storage=local-lvm
iso=/var/lib/vz/template/iso/Windows-Server-2025-Eval-X64-EN-US.iso
virtio_iso=/var/lib/vz/template/iso/virtio-win-0.1.271.iso
cores=4
memory=4096
disk_size=32

# Check if the VM with the same ID exists and delete it
if qm list | grep -q "$id"; then
    qm stop "$id"
    qm destroy "$id"
fi
# Create a new VM with the specified ID and name, using the host CPU type
qm create $id --name $name --cpu host
# Set the number of CPU cores for the VM
qm set $id --cores $cores
# Set the amount of memory for the VM
qm set $id --memory $memory
# Configure the network interface using VirtIO and bridge it to vmbr0
qm set $id --net0 virtio,bridge=vmbr0
# Set the SCSI controller type to VirtIO SCSI single
qm set $id --scsihw virtio-scsi-single
# Set the machine type to Q35
qm set $id --machine q35
# Set the BIOS type to OVMF (UEFI)
qm set $id --bios ovmf
# Create an EFI disk with raw format and pre-enrolled keys
qm set $id --efidisk0 ${storage}:1,format=raw,efitype=4m,pre-enrolled-keys=1,serial=EFI_DISK
# Create a TPM state storage with version 2.0
qm set $id --tpmstate0 ${storage}:1,version=v2.0,serial=TPM_DISK
# Create a SCSI disk with the specified size and raw format
qm set $id --scsi0 ${storage}:${disk_size},format=raw,serial=OS_DISK
# Set the CD-ROM drive to use the Windows ISO
qm set $id --ide2 $iso,media=cdrom
# Attach the VirtIO ISO as a CD-ROM on IDE3
qm set $id --ide3 $virtio_iso,media=cdrom
# Set the boot order to boot from the CD-ROM first
qm set $id --boot order='ide2;scsi0'
# Enable the QEMU agent and allow fstrim on cloned disks
qm set $id --agent enabled=1,fstrim_cloned_disks=1
# Enable the tablet device for better mouse support
qm set $id --tablet 1
# Set the OS type to Windows 11
qm set $id --ostype win11
# Allow hotplugging of disks, network interfaces, and USB devices
qm set $id --hotplug disk,network,usb
# Enable NUMA (Non-Uniform Memory Access)
qm set $id --numa 1
# Set the VGA type to VirtIO
qm set $id --vga virtio
# Display the VM configuration
qm config $id

echo "Windows Server 2025 VM Template ($name) successfully created with ID $id."
echo "Start the VM and proceed with Windows installation."
echo "After installation, install the VirtIO drivers and the QEMU Agent from the VirtIO ISO."