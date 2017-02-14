#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # BPM Gateware
    [[ -d bpm-gw ]] || ./get-repo-and-description.sh -b ${BPM_GW_VERSION} -r \
        https://github.com/lnls-dig/bpm-gw.git -d bpm-gw -m ${MANIFEST}
    # BPM IPMI
    [[ -d openMMC ]] || ./get-repo-and-description.sh -b ${BPM_IPMI_VERSION} -r \
        https://github.com/lnls-dig/openMMC -d openMMC -m ${MANIFEST}
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM gateware per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in bpm-gw openMMC; do
    cd $project && \
    git submodule update --init --recursive && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
