#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source environment variables
. ./env-vars.sh

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # ZEROmq libraries
    [[ -d libsodium ]] || ./get-repo-and-description.sh -b ${LIBSODIUM_VERSION} -r \
        https://github.com/jedisct1/libsodium.git -d libsodium -m ${MANIFEST}
    [[ -d libzmq    ]] || ./get-repo-and-description.sh -b ${LIBZMQ_VERSION} -r \
        https://github.com/zeromq/libzmq.git -d libzmq -m ${MANIFEST}
    [[ -d czmq      ]] || ./get-repo-and-description.sh -b ${CZMQ_VERSION} -r \
        https://github.com/zeromq/czmq.git -d czmq -m ${MANIFEST}
fi

# Patch repos
if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # Patch czmq repository, if version is less than 3.0.2
    if [ "${CZMQ_VERSION}" \< "v3.0.2" ] || [ "${CZMQ_VERSION}" == "v3.0.2" ]; then
        echo "CZMQ version ${CZMQ_VERSION} will be patched"
        cd czmq
        git am --ignore-whitespace ../patches/czmq/*
        cd ../
    fi
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM dependencies per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in libsodium libzmq czmq; do

    CONFIG_OPTS=()
    CONFIG_OPTS+=("CFLAGS=-Wno-format-truncation")
    CONFIG_OPTS+=("CPPFLAGS=-Wno-format-truncation")
    if [ $project == "libzmq" ]; then
        CONFIG_OPTS+=("PKG_CONFIG_PATH=/usr/local/lib/pkgconfig --with-libsodium")
    fi

    cd $project && \
    ./autogen.sh && \
    ./configure "${CONFIG_OPTS[@]}" && \
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
