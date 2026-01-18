#!/bin/bash

# Update package manager
apt-get update

# Install CPU microcode for security and bug fixes
echo "Installing CPU microcode..."
apt-get install -y amd64-microcode intel-microcode

## Most of this script is from https://github.com/community-scripts/ProxmoxVE/blob/main/tools/pve/post-pve-install.sh

# Cleanup legacy sources
echo "Cleaning up legacy repository files..."
rm -f /etc/apt/sources.list.d/*.list
rm -f /etc/apt/sources.list.d/*.sources
sed -i '/proxmox/d;/bookworm/d;/trixie/d' /etc/apt/sources.list 2>/dev/null || true

# Correcting Debian Base Sources (Trixie) - deb822 format
cat >/etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Configuring Proxmox VE no-subscription repository
cat >/etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Disabling Proxmox VE enterprise repository
cat >/etc/apt/sources.list.d/pve-enterprise.sources <<EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

# Adding Proxmox VE test repository (disabled)
cat >/etc/apt/sources.list.d/pve-test.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pvetest
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

# Configuring Ceph repositories (deb822 format) - Ceph Squid for PVE 9
cat >/etc/apt/sources.list.d/ceph.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg

Types: deb
URIs: https://enterprise.proxmox.com/debian/ceph-squid
Suites: trixie
Components: enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

# Install Proxmox Backup Server
apt-get update
apt-get install -y proxmox-backup-server

# Configuring Proxmox Backup Server no-subscription repository
cat >/etc/apt/sources.list.d/pbs.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Disabling Proxmox Backup Server enterprise repository
cat >/etc/apt/sources.list.d/pbs-enterprise.sources <<EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

# Adding Proxmox Backup Server test repository (disabled)
cat >/etc/apt/sources.list.d/pbs-test.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbstest
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

# Disabling subscription nag
echo "Disabling subscription nag..."
mkdir -p /usr/local/bin
cat >/usr/local/bin/pve-remove-nag.sh <<'EOFSCRIPT'
#!/bin/sh
WEB_JS=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
if [ -s "$WEB_JS" ] && ! grep -q NoMoreNagging "$WEB_JS"; then
    echo "Patching Web UI nag..."
    sed -i -e "/data\.status/ s/!//" -e "/data\.status/ s/active/NoMoreNagging/" "$WEB_JS"
fi

MOBILE_TPL=/usr/share/pve-yew-mobile-gui/index.html.tpl
MARKER="<!-- MANAGED BLOCK FOR MOBILE NAG -->"
if [ -f "$MOBILE_TPL" ] && ! grep -q "$MARKER" "$MOBILE_TPL"; then
    echo "Patching Mobile UI nag..."
    printf "%s\n" \
      "$MARKER" \
      "<script>" \
      "  function removeSubscriptionElements() {" \
      "    const dialogs = document.querySelectorAll('dialog.pwt-outer-dialog');" \
      "    dialogs.forEach(dialog => {" \
      "      const text = (dialog.textContent || '').toLowerCase();" \
      "      if (text.includes('subscription')) {" \
      "        dialog.remove();" \
      "      }" \
      "    });" \
      "    const cards = document.querySelectorAll('.pwt-card.pwt-p-2.pwt-d-flex.pwt-interactive.pwt-justify-content-center');" \
      "    cards.forEach(card => {" \
      "      const text = (card.textContent || '').toLowerCase();" \
      "      const hasButton = card.querySelector('button');" \
      "      if (!hasButton && text.includes('subscription')) {" \
      "        card.remove();" \
      "      }" \
      "    });" \
      "  }" \
      "  const observer = new MutationObserver(removeSubscriptionElements);" \
      "  observer.observe(document.body, { childList: true, subtree: true });" \
      "  removeSubscriptionElements();" \
      "  setInterval(removeSubscriptionElements, 300);" \
      "  setTimeout(() => {observer.disconnect();}, 10000);" \
      "</script>" \
      "" >> "$MOBILE_TPL"
fi
EOFSCRIPT
chmod 755 /usr/local/bin/pve-remove-nag.sh

echo 'DPkg::Post-Invoke { "/usr/local/bin/pve-remove-nag.sh"; };' >/etc/apt/apt.conf.d/no-nag-script
apt --reinstall install proxmox-widget-toolkit &>/dev/null

# Updating the package manager
echo "Updating package lists..."
apt-get update

# Disabling HA services but keeping Corosync. We want the cluster without HA.
echo "Configuring High Availability services..."
systemctl disable -q --now pve-ha-lrm
systemctl disable -q --now pve-ha-crm
systemctl enable -q --now corosync

# Adding QDevice packages
echo "Installing QDevice packages..."
apt-get install -y corosync-qdevice

# Set migration type to insecure in datacenter.cfg for unencrypted migration traffic
echo "Configuring migration settings..."
if ! grep -q '^migration:' /etc/pve/datacenter.cfg; then
    echo "migration: network=172.16.0.1/24,type=insecure" >> /etc/pve/datacenter.cfg
else
    sed -i 's/^migration:.*/migration: network=172.16.0.1\/24,type=insecure/' /etc/pve/datacenter.cfg
fi

# Updating Proxmox VE
echo "Updating Proxmox VE (this may take a while)..."
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y autoremove
apt-get -y autoclean

echo "Setup complete! System will reboot now..."
sleep 3

# Rebooting the system
reboot