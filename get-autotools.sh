#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e
set -x

echo "Installing Autotools"

# Source environment variables
. ./env-vars.sh

echo "$PKG_CONFIG_PATH"

# Install compatible autotools version not available in some
# distributions

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    wget http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz
    wget http://ftp.gnu.org/gnu/m4/m4-${M4_VERSION}.tar.gz
    wget http://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz
    wget http://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VERSION}.tar.gz
    wget http://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VERSION}.tar.gz
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing Autotools per user request (-i flag not set)"
    exit 0
fi

# Configure and Install libraries
for project in pkg-config-${PKG_CONFIG_VERSION} \
        m4-${M4_VERSION} \
        autoconf-${AUTOCONF_VERSION} \
        automake-${AUTOMAKE_VERSION} \
        libtool-${LIBTOOL_VERSION}; do
    tar xzvf ${project}.tar.gz && \
        cd $project && \
        ./configure &&
        make &&
        sudo make install && \
        sudo ldconfig && \
        cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done

echo "Autotools installation successfully completed"
