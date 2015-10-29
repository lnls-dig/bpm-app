#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

# Install compatible autotools version not available in some
# distributions

M4_VERSION=1.4.17
AUTOCONF_VERSION=2.69
AUTOMAKE_VERSION=1.14.1
LIBTOOL_VERSION=2.4.2
PKG_CONFIG_VERSION=0.26

wget http://ftp.gnu.org/gnu/m4/m4-${M4_VERSION}.tar.gz
wget http://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz
wget http://ftp.gnu.org/gnu/automake/automake-${AUTOMAKE_VERSION}.tar.gz
wget http://ftp.gnu.org/gnu/libtool/libtool-${LIBTOOL_VERSION}.tar.gz
wget http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz

# Configure and Install libraries
for project in m4-${M4_VERSION} autoconf-${AUTOCONF_VERSION} \
        automake-${AUTOMAKE_VERSION} libtool-${LIBTOOL_VERSION} \
        pkg-config-${PKG_CONFIG_VERSION}; do
    tar xzvf ${project}.tar.gz && \
        cd $project && \
        ./configure &&
        make check && \
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
