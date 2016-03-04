#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # BPM Client Software
    git clone --recursive --branch=${BPM_SW_CLI_VERSION} https://github.com/lnls-dig/bpm-sw-cli.git
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM client per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in bpm-sw-cli; do
    cd $project && \
    git submodule update --init --recursive && \
    sudo ./compile.sh ${BPM_SW_CLI_PREFIX} && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
