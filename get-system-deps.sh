#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

# Dependency list
GEN_DEPS="\
    binutils \
    git \
    re2c \
    linux-headers-`uname -r` \
    automake \
    autoconf \
    make \
    libtool
"
DEB_UBU_PERL_DEPS="\
    libextutils-cchecker-perl \
    libextutils-f77-perl \
    libextutils-libbuilder-perl \
    libextutils-pkgconfig-perl \
    libextutils-xsbuilder-perl \
    libextutils-xspp-perl
"
DEB_UBU_GEN_DEPS="\
    build-essential \
    g++ \
    glib2.0 \
    libglib2.0 \
    libglib2.0-dev \
    uuid-dev \
    libreadline6 \
    libreadline6-dev \
    libusb-dev \
    bzip2 \
    libbz2-dev \
    libxml2-dev \
    perl \
    libpng12-dev \
    libX11-dev \
    libXext-dev \
    libfreetype6 \
    libhdf5-dev
"
UBU_16_GEN_DEPS="\
    build-essential \
    g++ \
    glib2.0 \
    libglib2.0 \
    libglib2.0-dev \
    uuid-dev \
    libreadline6 \
    libreadline6-dev \
    libusb-dev \
    bzip2 \
    libbz2-dev \
    libxml2-dev \
    perl \
    libpng12-dev \
    libx11-dev \
    libxext-dev \
    libfreetype6 \
    libhdf5-dev
"
UBU_12_GEN_DEPS="\
    build-essential \
    g++ \
    glib2.0 \
    libglib2.0 \
    libglib2.0-dev \
    uuid-dev \
    libreadline6 \
    libreadline6-dev \
    libusb-dev \
    bzip2 \
    libbz2-dev \
    libxml2-dev \
    perl \
    libpng12-dev \
    libx11-dev \
    libxext-dev \
    libfreetype6 \
    libhdf5-serial-dev
"
DEB_UBU_DEPS="${DEB_UBU_GEN_DEPS} ${DEB_UBU_PERL_DEPS}"
UBU_16_DEPS="${UBU_16_GEN_DEPS} ${DEB_UBU_PERL_DEPS}"
UBU_12_DEPS="${UBU_12_GEN_DEPS} ${DEB_UBU_PERL_DEPS}"

FED_RED_SUS_DEPS="\
    gcc-c++ \
    glib2 \
    glib2-devel \
    uuid-devel \
    readline \
    readline-devel \
    libusb-devel \
    bzip2-devel \
    libxml2-devel \
    perl \
    perl-ExtUtils* \
    libpng-devel \
    libX11-devel \
    libXext-devel \
    freetype-devel
"

echo "Installing system dependencies"

distro=$(./get-os-distro.sh -d)
rev=$(./get-os-distro.sh -r)

case $distro in
    "Ubuntu" | "Debian")
        # Ubuntu 16 changed some package names
        if [ "$rev" \< "12.04" ] || [ "$rev" == "12.04" ]; then
            DEPS="${GEN_DEPS} ${UBU_12_DEPS}"
        elif [ "$rev" == "16.04" ]; then
            DEPS="${GEN_DEPS} ${UBU_16_DEPS}"
        else
            DEPS="${GEN_DEPS} ${DEB_UBU_DEPS}"
        fi

        PKG_MANAGER="apt-get"
        PKG_UPDT_COMMAND="update"
        PKG_INSTALL_COMMAND="install -y"
        ;;
    "Fedora" | "RedHat" | "Scientific")
        PKG_MANAGER="yum"
        PKG_UPDT_COMMAND="makecache"
        PKG_INSTALL_COMMAND="install -y"
        DEPS="${GEN_DEPS} ${FED_RED_SUS_DEPS}"
        ;;
    "SUSE")
        PKG_MANAGER="zypper"
        PKG_UPDT_COMMAND="update"
        # Not sure if this will assume "yes"" for every package, but zypper does
        # not seem to have an equivalent -y option
        PKG_INSTALL_COMMAND="--non-interactive --no-gpg-checks --quiet install \
            --auto-agree-with-licenses"
        DEPS="${GEN_DEPS} ${FED_RED_SUS_DEPS}"
        ;;
    *)
        echo "Unsupported distribution: $distro" >&2
        exit 1
        ;;
esac

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # Update repos
    sudo ${PKG_MANAGER} ${PKG_UPDT_COMMAND}
    sudo ${PKG_MANAGER} ${PKG_INSTALL_COMMAND} ${DEPS}
fi

echo "System dependencies installation completed"
