#! /bin/bash

################################################################################
# Script to install NVIDIA RTX 4060 Ti 16GB drivers on Ubuntu
# Author: Flash1212
# Date: 2026-06-09
#
# Description:
# This script automates the installation of NVIDIA drivers for the RTX 4060 Ti
# 16GB graphics card on Ubuntu. It includes steps to clean up existing NVIDIA
# drivers and modprobe files, install required dependencies, install the recommended
# NVIDIA drivers using ubuntu-drivers, and validate the installation by checking
# NVIDIA SMI and PCI devices.
#
# Notes:
# I used this script to install NVIDIA drivers on my older build:
#   Motherboard: MSI Z87-G45 Gaming (MS-7821 - LGA 1150)
#   Processor:   Intel Core i7-4771 CPU @ 3.50GHz
#   RAM:         32GB of DDR3 RAM
#   GPU:         NVIDIA RTX 4060 Ti 16GB
#
# Usage:
# You can configure the global variable's boolean at the top of the script to
# control which steps are executed when running in an IDE. If calling from the
# command line, you can pass the following arguments in order:
# 1. cleanup (true/false) - Whether to clean up existing NVIDIA drivers and
#    modprobe files
# 2. dependencies (true/false) - Whether to install required dependencies for
#    NVIDIA drivers
# 3. drivers (true/false) - Whether to install the recommended
#    NVIDIA drivers using ubuntu-drivers
# 4. validate (true/false) - Whether to validate the installation
#    by checking NVIDIA SMI and PCI devices
# Example command line usage:
# ./install_nvidia_rtx_4060ti_16gb.sh true true false false
#    <-- This will only clean up existing drivers and install dependencies, as reboot is required afterwards.
# ./install_nvidia_rtx_4060ti_16gb.sh false false true false
#    <-- This will only install NVIDIA drivers as reboot is required afterwards.
# ./install_nvidia_rtx_4060ti_16gb.sh false false false true <-- This will only validate the installation
#
# You cal also configure the script with environment variables as follows:
# export CLEANUP=true
# export DEPENDENCIES=true
# export DRIVERS=true
# export VALIDATE=true
# Then run the script without arguments:
# ./install_nvidia_rtx_4060ti_16gb.sh
#
# The order the script should be run in is as follows:
# 1. Clean up any existing NVIDIA drivers and modprobe files
# 2. Install required dependencies for NVIDIA drivers
# 3. Reboot the system to apply changes
# 4. Installs the recommended NVIDIA drivers using ubuntu-drivers
# 5. Reboot the system to apply NVIDIA driver installation
# 6. Validates the installation by checking NVIDIA SMI and PCI devices
################################################################################

cleanup="${1:-${CLEANUP:-false}}"
dependencies="${2:-${DEPENDENCIES:-false}}"
drivers="${3:-${DRIVERS:-false}}"
validate="${4:-${VALIDATE:-false}}"

function cleanup_modprobe() {
  echo "Cleaning up any existing NVIDIA modprobe files..."
  sudo rm -f /lib/modprobe.d/nvidia-graphics-drivers.conf
  sudo rm -f /lib/modprobe.d/nvidia-graphics-drivers.conf
  sudo rm -f /lib/modprobe.d/nvidia-installer-*
  sudo rm -f /etc/modprobe.d/nvidia-installer-*
}

function cleanup_nvidia() {
  echo "Cleaning up any existing NVIDIA drivers and CUDA toolkit..."
  sudo apt update
  sudo apt autoremove nvidia* --purge -y
  sudo apt remove --purge -y 'nvidia*' 'libnvidia*' 'cuda-*' 'libcuda*' 'nvidia-cuda-toolkit' cuda-keyring
  sudo apt autoremove --purge -y
}

function install_nvidia_dependencies() {
  echo "Installing required dependencies for NVIDIA drivers..."
  sudo apt update
  sudo apt install -y build-essential dkms "linux-headers-$(uname -r)"
}

function install_nvidia_drivers() {
  echo "Installing recommended NVIDIA drivers..."
  sudo ubuntu-drivers autoinstall
}

function validate_nvidia_installation() {
  echo "Validating NVIDIA driver installation..."
  nvidia-smi
  lspci -k | grep -A 2 -i "VGA\|3D\|Display"
}

main() {
  if [[ $cleanup == true ]]; then
    cleanup_nvidia
    cleanup_modprobe
  fi

  if [[ $dependencies == true ]]; then
    install_nvidia_dependencies
    echo "Rebooting the system to apply changes..."
    sudo reboot
  fi

  if [[ $drivers == true ]]; then
    install_nvidia_drivers
    echo "Rebooting the system to apply NVIDIA driver installation..."
    sudo reboot
  fi

  if [[ $validate == true ]]; then
    validation=$(validate_nvidia_installation)
    echo "$validation"
    if [[ $validation == *"Kernel driver in use: nvidia"* ]]; then
      echo "NVIDIA driver installation validated successfully!"
    else
      echo "NVIDIA driver installation validation failed. Please check the output above for details."
    fi
  fi
}

main "$cleanup" "$dependencies" "$drivers" "$validate"
