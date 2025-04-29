#!/bin/bash
# Disable root password authentication 
#sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
#systemctl restart sshd

# Update package manager
apt-get update

## Most of this script is from https://github.com/community-scripts/ProxmoxVE/blob/main/tools/pve/post-pve-install.sh
# Correcting Proxmox VE Sources
cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-bookworm-firmware.conf

# Disabling 'pve-enterprise' repository
cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF

# Enabling 'pve-no-subscription' repository
cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# Correcting 'ceph package repositories'
cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
# deb https://enterprise.proxmox.com/debian/ceph-reef bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
EOF

# Adding 'pvetest' repository and set disabled
cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF

# Disabling subscription nag
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
apt --reinstall install proxmox-widget-toolkit

# Updating the package manager
apt-get update

# Disableing HA services but keeping Corosync. We want the cluster without HA.
systemctl disable -q --now pve-ha-lrm
systemctl disable -q --now pve-ha-crm
systemctl enable -q --now corosync

# Adding QDevice packages
apt-get install -y corosync-qdevice

# Set migration type to insecure in datacenter.cfg for unencrypted migration traffic
if ! grep -q '^migration:' /etc/pve/datacenter.cfg; then
    echo "migration: network=172.16.0.1/24,type=insecure" >> /etc/pve/datacenter.cfg
else
    sed -i 's/^migration:.*/migration: network=172.16.0.1\/24,type=insecure/' /etc/pve/datacenter.cfg
fi

# Updating Proxmox VE
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y autoremove
apt-get -y autoclean

# Rebooting the system
reboot