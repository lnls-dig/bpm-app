#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # ZEROmq libraries
    git clone --branch=${LIBSODIUM_VERSION} https://github.com/jedisct1/libsodium.git
    git clone --branch=${LIBZMQ_VERSION} https://github.com/lnls-dig/libzmq.git
    git clone --branch=${CZMQ_VERSION} https://github.com/zeromq/czmq.git
    git clone --branch=${MALAMUTE_VERSION} https://github.com/lnls-dig/malamute.git
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM dependencies per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in libsodium libzmq czmq; do
    cd $project && \
    ./autogen.sh && \
    ./configure &&
    make check && \
    make && \
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

# Configure and Install
for project in malamute; do
    cd $project && \
    ./autogen.sh && \
    ./configure --with-systemd-units &&
    make check && \
    make && \
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
