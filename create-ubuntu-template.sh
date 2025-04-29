#!/bin/bash
# Set the variables
id=9000
name=ubuntu-24
storage=local-lvm
disk=/var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img
cores=4
memory=4096
user=user
password=password

# Update the package list and upgrade the system
apt update -y
# Install the libguestfs-tools package
apt install libguestfs-tools -y
# Install the QEMU Guest Agent and disable password login
virt-customize -a "$disk" --install qemu-guest-agent
# Check if the VM with the same ID exists and delete it
if qm list | grep -q "$id"; then
    qm stop "$id"
    qm destroy "$id"
fi
# Create a new VM with the ID id and the name name
qm create "$id" --memory $memory --core $cores --name "$name" --net0 virtio,bridge=vmbr0
# Import the name cloud image to the storage storage
qm disk import "$id" "$disk" "$storage"
# Set the id VM to use the storage storage
qm set "$id" --scsihw virtio-scsi-pci --scsi0 "$storage":vm-"$id"-disk-0
# Set the id VM to use the storage cloudinit storage
qm set "$id" --ide2 "$storage":cloudinit
# set boot from the storage cloud image
qm set "$id" --boot c --bootdisk scsi0
# create a serial port and set it as the primary display
qm set "$id" --serial0 socket --vga serial0
# Enable QEUM Guest Agent
qm set "$id" --agent enabled=1
# use the user "user"
qm set "$id" --ciuser "$user"
# set the password for the user "user"
qm set "$id" --cipassword "$password"
# use DHCP
qm set "$id" --ipconfig0 ip=dhcp
# Convert the VM to a Template
qm template "$id"