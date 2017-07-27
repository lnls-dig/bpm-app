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
    [[ -d malamute  ]] || ./get-repo-and-description.sh -b ${MALAMUTE_VERSION} -r \
        https://github.com/lnls-dig/malamute.git -d malamute -m ${MANIFEST}
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

    # Patch malamute repository to avoid filling logsystem with dummy messages
    if [ "${MALAMUTE_VERSION}" \> "v1.0" ] || [ "${MALAMUTE_VERSION}" == "v1.0" ]; then
        echo "MALAMUTE version ${MALAMUTE_VERSION} will be patched"
        cd malamute
        git am --ignore-whitespace ../patches/malamute/*
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

TOP_DIR=$(pwd)

# Configure and Install
for project in malamute; do
    cd $project && \
    ./autogen.sh && \
    ./configure --with-systemd-units --sysconfdir=/usr/etc --prefix=/usr &&
    make check && \
    make && \
    sudo make install && \
    sudo ldconfig && \
    cd ..

    MALAMUTE_VERBOSE=0
    MALAMUTE_PLAIN_AUTH=
    MALAMUTE_AUTH_MECHANISM=null
    MALAMUTE_ENDPOINT='ipc:///tmp/malamute'
    MALAMUTE_CFG_FILE=/usr/etc/malamute/malamute.cfg
    # Install our custom Malamute config file
    sudo sed -i \
        -e "s|verbose\( *\)=.*|verbose\1= ${MALAMUTE_VERBOSE}|g" \
        -e "s|plain\( *\)=.*|plain\1= ${MALAMUTE_PLAIN_AUTH}|g" \
        -e "s|mechanism\( *\)=.*|mechanism\1= ${MALAMUTE_AUTH_MECHANISM}|g" \
        -e "s|tcp://\*:9999|${MALAMUTE_ENDPOINT}|g" \
        ${MALAMUTE_CFG_FILE}


    # Enable service
    sudo systemctl enable malamute

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
