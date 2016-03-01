#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # BPM Software
    git clone --branch=${BPM_SW_VERSION} https://github.com/lnls-dig/bpm-sw.git
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM server per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in bpm-sw; do
    cd $project && \
    git submodule update --init --recursive && \
    sudo ./compile.sh -b ${BOARD} -a ${BPM_SW_APPS} -e ${BPM_SW_WITH_EXAMPLES} -l ${BPM_SW_WITH_LIBS_LINK} && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
