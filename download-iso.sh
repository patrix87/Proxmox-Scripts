#!/bin/bash
# Set the variables
ubuntu_version="24.04"
image_url=https://cloud-images.ubuntu.com/releases/${ubuntu_version}/release/ubuntu-${ubuntu_version}-server-cloudimg-amd64.img
image_checksum_url=https://cloud-images.ubuntu.com/releases/${ubuntu_version}/release/SHA256SUMS
image_gpg_url=https://cloud-images.ubuntu.com/releases/${ubuntu_version}/release/SHA256SUMS.gpg
image_target_directory=/var/lib/vz/template/iso
key_server=hkp://keyserver.ubuntu.com:80
image_file=$(basename "$image_url")
checksum_file=$(basename "$image_checksum_url")
signature_file=$(basename "$image_gpg_url")
declare -A other_iso
other_iso=(
    ["virtio-win-0.1.285.iso"]="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso"
    ["Windows-Server-2025-OEM-X64-EN-US.iso"]="https://oemsoc.download.prss.microsoft.com/dbazure/X23-81958_26100.1742.240906-0331.ge_release_svc_refresh_SERVER_OEMRET_x64FRE_en-us.iso_909fa35d-ba98-407d-9fef-8df76f75e133?t=34b8db0f-439b-497c-86ce-ec7ceb898bb7&P1=102816956391&P2=601&P3=2&P4=pG1WoVpBKlyWcmfj%2bt1gYgkTsP4At28ch8mG7vIQm%2fT4elz5v2ZQ3eKAN8%2fFjb1yaa4npBaABURtnI8YmrDv8p0VJmYpLCIUQ0FHEFR4IFiPgtvzwAAI8oNdiEl%2b2uM7MN8Gaju8BvIVgHRl%2fRxq0HFgrFoEGmvHZU4jY0RFsYAaHliUinDUzdVfT0IPwyWqNUJXZTSfguyphv8XZx8OQsBy3zwBp7tNHsKl36ZO2JdZK%2fyPY7QTpAr5ccazUPEa40ALhYRBJXxlQb1F0OeO7kHhW7DKK5D4Wpt5WbpjFn8MqcZBX3%2fQI6WAwzDSKIck7jYL7bYdl2ufoMRrFZrxxw%3d%3d"
)

# Check if the target directory exists create it if it does not
if [ ! -d "$image_target_directory" ]; then
    mkdir -p "$image_target_directory"
fi
# Change directory to the target directory
cd "$image_target_directory" || exit 1

# Download the checksum files
wget "${image_checksum_url}" -O "${checksum_file}"
wget "${image_gpg_url}" -O "${signature_file}"

# Verify the checksum files and capture the output to download the keys if the checksum files are not verified
KEY=$(gpg --verify --keyid-format long --with-colons "$signature_file" "$checksum_file" 2>&1 | grep 'using RSA key' | awk '{print $5}')

# Ensure the GPG key is present
if ! gpg --list-keys "$KEY" > /dev/null 2>&1; then
    echo "GPG key $KEY not found. Downloading..."
    if ! gpg --keyserver "$key_server" --recv-keys "$KEY"; then
        echo "Failed to download GPG key. Exiting."
        exit 1
    fi
fi

# Verify the checksum signature
echo "Verifying checksum signature..."
if ! gpg --verify "$signature_file" "$checksum_file"; then
    echo "Checksum signature verification failed. Exiting."
    exit 1
fi

# Function to validate the image checksum
validate_checksum() {
    echo "Validating image file checksum..."
    checksum_result=$(sha256sum -c "$checksum_file" 2>&1 | grep "$image_file")
    if echo "$checksum_result" | grep -q ": OK"; then
        echo "Image file checksum is valid. Validation successful!"
        return 0
    else
        echo "Image file checksum validation failed!"
        return 1
    fi
}

# Check and validate the image file
if [ -f "$image_file" ]; then
    echo "Image file found. Validating..."
    if ! validate_checksum; then
        echo "Checksum failed. Re-downloading image file..."
        wget "$image_url" -O "$image_file"
        echo "Re-validating image file after download..."
        if ! validate_checksum; then
            echo "Validation failed even after re-downloading. Exiting."
            exit 1
        fi
    fi
else
    echo "Image file not found. Downloading..."
    wget "$image_url" -O "$image_file"
    echo "Validating image file..."
    if ! validate_checksum; then
        echo "Image file validation failed after download. Exiting."
        exit 1
    fi
fi

# Cleanup the checksum and signature files
rm SHA256SUMS SHA256SUMS.gpg

# Download other ISOs
for iso_name in "${!other_iso[@]}"; do
    iso_url="${other_iso[$iso_name]}"
    wget "$iso_url" -O "$iso_name"
done