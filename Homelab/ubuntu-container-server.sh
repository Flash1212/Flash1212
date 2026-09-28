#!/bin/bash
# Homelab Ubuntu Server Setup Script
# For OptiPlex 5060 Micro -> TrueNAS NUC13 Pro

set -euo pipefail

# --- CONFIGURATION ---
CURRENT_USER=$(whoami)
NUC_IP="10.10.10.1"
SHARE_NAME="containers"
MOUNT_POINT="/mnt/storage"
USB_INTERFACE="..." # Add the ethernet interface name
NATIVE_INTERFACE="..." # Add the native interface name
SMB_USER="container_admin"
SMB_CRED_FILE="/home/$CURRENT_USER/.smbcreds"

echo "=== Homelab Setup Script ==="
read -rsp "Enter SMB password for $SMB_USER: " SMB_PASSWORD
echo

echo "[1/4] Configuring user primary group..."
if ! getent group storage_admins >/dev/null 2>&1; then
    sudo groupadd storage_admins
fi

sudo usermod -g storage_admins "$CURRENT_USER"
echo "  Primary group set to storage_admins for $CURRENT_USER"

echo "[2/4] Configuring network..."
ACTUAL_USB_IF=$(ip -o link show | grep "$USB_INTERFACE" | awk -F": " "{print \$2}" | cut -d"@" -f1 || echo "")
ACTUAL_NATIVE_IF=$(ip -o link show | grep "$NATIVE_INTERFACE" | awk -F": " "{print \$2}" | cut -d"@" -f1 || echo "")

if [ -z "$ACTUAL_USB_IF" ]; then
    echo "  USB-C interface not found:"
    ip -o link show
    read -rp "  Enter USB-C interface name: " ACTUAL_USB_IF
fi

if [ -z "$ACTUAL_NATIVE_IF" ]; then
    ACTUAL_NATIVE_IF=$(ip -o link show | grep "state UP" | awk -F": " "{print \$2}" | cut -d"@" -f1 | head -n1)
fi

USB_MAC=$(ip link show "$ACTUAL_USB_IF" | grep link/ether | awk "{print \$2}")
NETPLAN_FILE="/etc/netplan/01-homelab.yaml"

sudo tee "$NETPLAN_FILE" > /dev/null <<EOF
network:
  version: 2
  ethernets:
    ${ACTUAL_NATIVE_IF}:
      dhcp4: true
      dhcp6: true
    ${ACTUAL_USB_IF}:
      dhcp4: false
      addresses:
        - 10.10.10.2/24
      match:
        macaddress: ${USB_MAC}
EOF

echo "  Applying netplan (auto-reverts in 120s on failure)..."
if ! sudo netplan try; then
    echo "  Netplan failed or connection lost. Aborting."
    exit 1
fi

if ! ping -c 3 -W 2 "$NUC_IP" >/dev/null 2>&1; then
    echo "  Cannot reach NUC at $NUC_IP. Check cable/interface."
    exit 1
fi
echo "  NUC reachable"

echo "[3/4] Setting up SMB mount..."
cat > /tmp/.smbcreds.tmp <<EOF
username=${SMB_USER}
password=${SMB_PASSWORD}
domain=
EOF
sudo mv /tmp/.smbcreds.tmp "$SMB_CRED_FILE"
sudo chmod 600 "$SMB_CRED_FILE"
sudo chown "$CURRENT_USER:storage_admins" "$SMB_CRED_FILE"

sudo mkdir -p "$MOUNT_POINT"

FSTAB_ENTRY="//${NUC_IP}/${SHARE_NAME} ${MOUNT_POINT} cifs vers=3.1.1,cache=loose,credentials=${SMB_CRED_FILE},noserverino,_netdev,users 0 0"
if ! grep -q "$MOUNT_POINT" /etc/fstab 2>/dev/null; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab >/dev/null
fi

umount "$MOUNT_POINT" 2>/dev/null || true
mount -a
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "  Mount failed. Check credentials and share."
    exit 1
fi
touch "${MOUNT_POINT}/.setup_test" && rm "${MOUNT_POINT}/.setup_test"
echo "  SMB mount verified"

echo "[4/4] Installing Docker..."
if command -v docker >/dev/null 2>&1; then
    echo "  Docker already installed"
else
    curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$CURRENT_USER"

echo ""
echo "=== Setup Complete ==="
echo "  Storage: $MOUNT_POINT via $ACTUAL_USB_IF -> $NUC_IP"
echo "  Dockge: http://$(hostname -I | awk '{print $1}'):5001"
echo ""
echo "  Next: log out/in to refresh groups, then open Dockge"