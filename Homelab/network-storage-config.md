# Homelab Network & Storage Configuration

## Hardware

- TrueNAS (NUC13ANKi3): 2x WD HC580 22TB (Mirror), ThunderBay 4 (OWC, Thunderbolt)
- OptiPlex 5060 Micro: Ubuntu Server 26.04.1, Arcane
- Network: 2x Intel i225-V USB-C 2.5GbE adapters, Cat6 patch cable

## Network Topology

| Interface | Machine | IP | Purpose |
| ----------- | --------- | ---- | --------- |
| enp86s0 (Native 2.5GbE) | NUC | 10.10.10.1/24 | Storage link to OptiPlex |
| enx5c857e36e7f8 (USB-C) | NUC | DHCP (Pace GW) | Internet |
| enx5c857e36e7bc (USB-C) | OptiPlex | 10.10.10.2/24 | Storage link to NUC |
| eno1 (Native 1GbE) | OptiPlex | DHCP (Pace GW) | Internet |

## TrueNAS Configuration

### 1. Thunderbolt Persistence

- Method: UDEV tunable via TrueNAS GUI (System → Advanced Settings → Sysctl)

```txt
Variable: 99-thunderbolt-auto
Value: ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
Description: Thunderbolt Persistence
```

- Why: To survive on system restarts and reboots /etc resets; fires at enumeration, no race conditions
- Status: Working

### 2. Credentials

- Users:
  - Username: container_admin
  - Full Name: Container Admin
  - Type: Local
  - UID: 1000
  - Allow Access
    - SMB Access

- Groups
  - Group Name: storage_amdins
  - GID: 1001
  - SMB Group

### 3. Dataset & SMB Share

- Create Dataset:
  - Dataset Name: containers
  - Dataset Preset: SMB
  - After Creation edit Advanced Options
    - ACL Mode: Pass through

- SMB Share:
  - Purpose: `Default Share`
  - Path: `/mnt/Thunderbay/containers`
  - Share Name: `containers`
  - SMB User/Group: `container_admin:storage_admins (UID 1000, GID 1001)`
  - Description: `Dataset where containers will write`
- Share  ACL Entries:
  - Who: everyone@
  - Permissions: FULL
  - Type: ALLOWED
- File ACL:
  - Owner: container_admin
  - Owner Group: storage_admins
  - Who: owner@
  - ACL Type: Allow
  - Permissions Type: Basic
  - Permissions: Full Control

## Ubuntu Server Configuration

### 1. User & Group

- User: flash1212 (UID 1000)
- Primary Group: storage_admins (GID 1001) — changed from default
- Membership: storage_admins, docker, sudo, etc.

### 2. Network

- Netplan: Static IP 10.10.10.2/24 on USB-C adapter, no gateway
- Internet: DHCP on native 1GbE
- Gateway: Only one default route (via eno1)

### 3. SMB Mount (/etc/fstab)

```txt
//10.10.10.1/containers /mnt/storage cifs vers=3.1.1,cache=loose,credentials=/home/flash1212/.smbcreds,forceuid=1000,forcegid=1001,_netdev,users 0 0
```

### 4. Credentials

- File: /home/flash1212/.smbcreds
- Content:

```txt
username=container_admin,
password=<pw>,
domain=
```

- Permissions: chmod 600
