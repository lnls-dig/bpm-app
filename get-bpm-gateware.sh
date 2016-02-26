#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

# BPM Gateware
git clone --branch=${BPM_GW_VERSION} https://github.com/lnls-dig/bpm-gw.git
# BPM IPMI
git clone --branch=${BPM_IPMI_VERSION} https://github.com/lnls-dig/afcipm.git

# Configure and Install
for project in bpm-gw bpm-ipmi; do
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
