#! /bin/bash

# Install Spotify through Debian
# Source: https://www.spotify.com/us/download/linux/

function aider {
  echo "Installing Aider ..."

  python -m pip install pipx  # If you need to install pipx
  pipx install aider-install setuptools
  aider-install
}

function spotify {
  echo "Installing Spotify dependencies..."

  curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc |
    sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg

  echo "deb https://repository.spotify.com stable non-free" |
    sudo tee /etc/apt/sources.list.d/spotify.list

  sudo apt-get update
  sudo apt-get install -y spotify-client
}

# Install Steam on Ubuntu with NVIDIA drivers
# Source: https://linuxcapable.com/how-to-install-steam-on-ubuntu-linux/
function steam {
  echo "Installing Steam dependencies..."
  # Update package lists, upgrade existing packages, and install necessary dependencies for Steam
  sudo apt update
  # Upgrade existing packages to ensure compatibility and security
  sudo apt upgrade -y
  # Install essential dependencies for Steam, including support for 32-bit architecture and tools for managing software repositories
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  # Add support for 32-bit architecture, which is required for running many Steam games that are not available in 64-bit versions
  sudo dpkg --add-architecture i386
  sudo apt update

  echo "Installing Steam from the official Ubuntu repository..."

  # Download and add the Steam GPG key to the system's keyring
  sudo curl -fsSLo /usr/share/keyrings/steam.gpg https://repo.steampowered.com/steam/archive/stable/steam.gpg
  sudo chmod 0644 /usr/share/keyrings/steam.gpg

  # Add the Steam repository to the system's sources list
  printf '%s\n' \
  'Types: deb' \
  'URIs: https://repo.steampowered.com/steam/' \
  'Suites: stable' \
  'Components: steam' \
  'Architectures: amd64 i386' \
  'Signed-By: /usr/share/keyrings/steam.gpg' |
    sudo tee /etc/apt/sources.list.d/steam.sources >/dev/null

  # Refresh package lists to include the Steam repository
  sudo apt update

  # Install Valve's official Steam package
  sudo apt install -y steam-launcher

  if [[ -f "/etc/apt/sources.list.d/steam-stable.list" ]]; then
    echo "Removing old (duplicate) Steam repository source list..."
    sudo rm -f /etc/apt/sources.list.d/steam-stable.list
  fi

  # Verify that Steam was installed successfully by checking the package list
  dpkg -l | grep steam
}

aider
steam
spotify
