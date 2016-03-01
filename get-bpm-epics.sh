#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    git clone --branch=${BPM_EPICS_IOC_VERSION} https://github.com/lnls-dig/bpm-epics-ioc.git
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM EPICS IOC per user request (-i flag not set)"
    exit 0
fi

# Configure and Install IOC BPM
for project in bpm-epics-ioc; do
    cd $project && \
    git submodule update --init --recursive && \
    make && \
    make install && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
