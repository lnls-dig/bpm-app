#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source repo versions
. ./repo-versions.sh

git clone --branch=${BPM_EPICS_IOC_VERSION} https://github.com/lnls-dig/bpm-epics-ioc.git

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
