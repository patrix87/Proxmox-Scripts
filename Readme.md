# My collection of Proxmox Shell Scripts

Below is a list of all scripts in this repository with a short description of each:

- **create-ubuntu-template.sh**  
  Automates the creation of an Ubuntu 24.04 VM template using a cloud image, sets up user/password, enables QEMU guest agent, and converts the VM to a template.

- **create-windows-template.sh**  
  Creates a Windows Server 2025 VM template, sets up storage, TPM, EFI, VirtIO drivers, and prepares the VM for installation and later conversion to a template.

- **restore-windows-template-from-volumes.sh**  
  Restores or recreates a Windows Server 2025 VM template from existing disk volumes, configuring all necessary VM hardware and settings.

- **download-iso.sh**  
  Downloads the latest Ubuntu cloud image and Windows Server 2025 Eval as well as other ISOs (such as VirtIO drivers), verifies checksums and signatures, and places them in the Proxmox ISO directory.

- **setup-script.sh**  
  Sets up and configures a Proxmox VE host: updates repositories, disables subscription nag, configures sources, disables HA services, installs QDevice, and updates the system.
