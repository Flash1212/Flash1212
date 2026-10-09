#! /bin/bash
set -eo pipefail

# Ignore crlf when coding on windows for linux, I know the irony...
# shellcheck disable=SC1017

###################### helper functions ######################
function help_response() {
	local code="${1:-0}"
	local notification

	notification="$NOTICE"
	if [[ "$code" -ne 0 ]]; then
		notification="$WARN"
	fi

	echo -e "$notification Displaying help information..."
	# Display help information here
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo "  --aider,   Install Aider"
	echo "  --podman,  Install Podman"
	echo "  --spotify, Install Spotify"
	echo "  --steam,   Install Steam"
	echo "    usage: $0 --aider --spotify"
	echo "  -help, -h, -?, --help Display this help message"
	exit "$code"
}

###################### Installer functions ######################
# Function to install Aider
#
# serioustavern: [Aider](https://aider.chat/) is the OG open-source AI coding
# assistant which inspired many other tools.
# Installation instructions from: https://aider.chat/docs/install.html
#################################################################
function aider {
	echo "$NOTICE Installing Aider ..."

	python -m pip install pipx  # If you need to install pipx
	pipx install aider-install setuptools
	aider-install

	echo "$SUCCESS Installed Aider"
}

#################################################################
# Function to install Podman
#
# Podman (pod manager) is an open source Open Container Initiative
# (OCI)-compliant container management tool created by Red Hat used for
# handling containers, images, volumes, and pods on the Linux operating
# system, with support for macOS and Microsoft Windows via a virtual machine.
#
# We're installing Podman 5.3.0 on Kubuntu 24.04 LTS (Noble Numbat) so we must
# use APT pinning to pull the package from the newer Ubuntu 25.04 (Plucky)
# repository, as the official Noble repository only contains version 4.9.3.
#
# I'm installing this version to avoid issues with quadlets not staying active
# aster starting. Fixes I require came in 5.3.0.
#################################################################
function podman {
	echo "Installing Podman ..."

	function podman_apt_pinning {
		sudo mkdir -p /etc/apt/sources.list.d
		echo "deb http://archive.ubuntu.com/ubuntu plucky main universe" |
			sudo tee /etc/apt/sources.list.d/plucky.list

		sudo tee /etc/apt/preferences.d/podman-plucky.pref > /dev/null <<- EOF
		Package: podman buildah golang-github-containers-common crun libgpgme11t64 libgpg-error0 golang-github-containers-image catatonit conmon containers-storage
		Pin: release n=plucky
		Pin-Priority: 991

		Package: libsubid4 netavark passt aardvark-dns containernetworking-plugins libslirp0 slirp4netns
		Pin: release n=plucky
		Pin-Priority: 991

		Package: *
		Pin: release n=plucky
		Pin-Priority: 400
		EOF
	}

	echo "Pinning plucky apt source for podman 5.x"
	podman_apt_pinning

	echo "Install Podman and some dependencies"
	sudo apt-get update && sudo apt-get install -y \
		ca-certificates curl gnupg lsb-release software-properties-common

	echo "Install Podman and some dependencies"
	sudo apt-get install -y podman

	echo "$SUCCESS Installed Podman"
}
#################################################################
# Function to install Spotify
#
# Source: https://www.spotify.com/us/download/linux/
#################################################################
function spotify {
	echo "Installing Spotify dependencies..."

	curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc |
		sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg

	echo "deb https://repository.spotify.com stable non-free" |
		sudo tee /etc/apt/sources.list.d/spotify.list

	sudo apt-get update
	sudo apt-get install -y spotify-client

	echo "$SUCCESS Installed Spotify"
}

#################################################################
# Function to install Steam
#
# Steam  on Ubuntu with NVIDIA drivers
# Source: https://linuxcapable.com/how-to-install-steam-on-ubuntu-linux/
#################################################################
function steam {
	echo "Installing Steam dependencies..."
	# Update package lists, upgrade existing packages, and install necessary
	# dependencies for Steam
	sudo apt-get update
	# Upgrade existing packages to ensure compatibility and security
	sudo apt-get upgrade -y
	# Install essential dependencies for Steam, including support for 32-bit
	#architecture and tools for managing software repositories
	sudo apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		software-properties-common
	# Add support for 32-bit architecture, which is required for running many
	# Steam games that are not available in 64-bit versions
	sudo dpkg \
		--add-architecture i386
	sudo apt-get update

	echo "Installing Steam from the official Ubuntu repository..."

	# Download and add the Steam GPG key to the system's keyring
	sudo curl \
		-fsSLo /usr/share/keyrings/steam.gpg \
		https://repo.steampowered.com/steam/archive/stable/steam.gpg
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
	sudo apt-get update

	# Install Valve's official Steam package
	sudo apt-get install -y steam-launcher

	if [[ -f "/etc/apt/sources.list.d/steam-stable.list" ]]; then
		echo "Removing old (duplicate) Steam repository source list..."
		sudo rm -f /etc/apt/sources.list.d/steam-stable.list
	fi

	# Verify that Steam was installed successfully by checking the package list
	dpkg -l | grep steam

	echo "$SUCCESS Installed Steam"
}


###################### Color Codes ######################
NC='\033[0m'

GREEN='\033[0;32m'
SUCCESS="${GREEN}[SUCCESS]:${NC}"

BLUE='\033[0;34m'
NOTICE="${BLUE}[NOTICE]:${NC}"

RED='\033[0;31m'
ERROR="${RED}[ERROR]:${NC}"

YELLOW='\033[0;33m'
WARN="${YELLOW}[WARNING]:${NC}"

##################### Argument Variables ######################
AIDER=false
PODMAN=false
SPOTIFY=false
STEAM=false
HELP=false
##################### Argument Parsing ######################
while [[ $# -gt 0 ]]; do
	case "$1" in
	--aider)
		AIDER=true
		shift
		;;
	--podman)
		PODMAN=true
		shift
		;;
	--spotify)
		SPOTIFY=true
		shift
		;;
	--steam)
		STEAM=true
		shift
		;;
	--help | -help | -h | -?)
		HELP=true
		break
		;;
	*)
		echo -e "$ERROR Unknown command/flag: $1"
		help_response 1
		;;
	esac
done
##################### Argument Parsing ######################

if [[ "$HELP" == true ]]; then
	help_response
fi

if ! "$AIDER" && ! "$PODMAN" && ! "$SPOTIFY" && ! "$STEAM"; then
	help_response 1
fi

if [[ "$AIDER" == true ]]; then aider; fi
if [[ "$PODMAN" == true ]]; then podman; fi
if [[ "$SPOTIFY" == true ]]; then steam; fi
if [[ "$STEAM" == true ]]; then spotify; fi
