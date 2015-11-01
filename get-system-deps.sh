#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

# Dependency list
GEN_DEPS="binutils build-essential git re2c libreadline6 perl5" 
DEB_UBU_DEPS="glib2.0 libglib2.0 libglib2.0-dev uuid-dev libreadline6-dev"
FED_RED_SUS_DEPS="glib2.0 libglib2.0 libglib2.0-devel uuid-devel libreadline6-devel"

echo "Installing system dependencies"

distro=$(./get-os-distro.sh -d)

case $distro in
    "Ubuntu" | "Debian")
        PKG_MANAGER="apt-get"
        PKG_UPDT_COMMAND="update"
        PKG_INSTALL_COMMAND="install -y"
        DEPS="${GEN_DEPS} ${DEB_UBU_DEPS}"
        ;;
    "Fedora" | "Redhat" | "SUSE")
        PKG_MANAGER="yum"
        PKG_UPDT_COMMAND="update"
        PKG_INSTALL_COMMAND="install -y"
        DEPS="${GEN_DEPS} ${FED_RED_SUS_DEPS}"
        ;;
    *)
        echo "Unsupported distribution: $distro" >&2
        exit 1
        ;;
esac

# Update repos
sudo ${PKG_MANAGER} ${PKG_UPDT_COMMAND}
sudo ${PKG_MANAGER} ${PKG_COMMAND} ${DEPS}

# Add GLIB pkg0config file (*.pc) to pkg-config path, so
# a possible update on pkg-config works
GLIB_PKG_CONFIG_PATH=$(find /usr/ -iname "glib-2.0.pc)
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${GLIB_PKG_CONFIG_PATH}

echo "System dependencies installation completed"
